class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :patches, dependent: :destroy
  has_many :timelines, :as => :timelineable, dependent: :destroy

  serialize :properties, ActiveRecord::Coders::Hstore

  acts_as_ordered_taggable_on :tags, :origins

  # gaining with simple_enum Gem here..
  as_enum :category, { :tip       => 1,
                       :quote     => 2,
                       :fact      => 3,
                       :problem   => 4,
                       :question  => 5 },
          # Use "is_" prefix so that category could be
          # accessed via post.is_tip? or post.is_quote!
          :prefix => 'is'
  validates_as_enum :category

  is_impressionable :counter_cache => { :column_name => :views_count }

  attr_accessible :body, :user_id,
                  :category, :tag_list, :origin_list,
                  :description

  validates :body, presence: true, length: { minimum: 10 }

  validates :tag_list, presence: true
  validates_format_of [:origin_list, :tag_list], :with => /\A(,?[\w\d\s\.]{2,20}){0,5}\z/,
                      :message => 'Should only contain: letters, numbers, periods and underscores'

  after_create :add_to_timeline, :increment_author_posts_counter
  after_destroy :decrement_author_posts_counter

  def self.latest(params)
    paginate(page: params[:page], order: 'created_at DESC', per_page: 3)
  end

  def self.popular(params)
    paginate(page: params[:page],
             order: 'views_count DESC, likes_count DESC, comments_count DESC',
             per_page: 3)
  end

  def self.search(params)
    where("body LIKE ?", "%#{params[:keyword]}%").paginate(page: params[:page], order: 'created_at DESC', per_page: 3)
  end

  def self.from_users_followed_by(user)
    where("user_id IN (?)", user.followed_user_ids)
  end

  def create_repository(user)

    repo = Rugged::Repository.init_at "./posts/#{self.id}", true
    index = Rugged::Index.new

    oid = repo.write(append_whitespace(self.body.gsub(/\r\n?/, "\n")), :blob)
    index.add(:path => "#{self.category.to_s}.md", :oid => oid, :mode => 0100644)

    if self.category.to_s === 'problem' and !self.solution.blank?
      oid = repo.write(append_whitespace(self.solution.gsub(/\r\n?/, "\n")), :blob)
      index.add(:path => "solution.md", :oid => oid, :mode => 0100644)
    end
    if self.category.to_s === 'question' and !self.answer.blank?
      oid = repo.write(append_whitespace(self.answer.gsub(/\r\n?/, "\n")), :blob)
      index.add(:path => "answer.md", :oid => oid, :mode => 0100644)
    end

    unless self.description.blank?
      oid = repo.write(append_whitespace(self.description.gsub(/\r\n?/, "\n")), :blob)
      index.add(:path => "README.md", :oid => oid, :mode => 0100644)
    end

      # Concatenate META attributes into one string in YAML format
      meta = "category: #{self.category.to_s}\n"
      meta << "tags:\n"
      self.tag_list.each { |t| meta << "  - #{t}\n" }
      meta << "origins:\n"
      self.origin_list.each { |t| meta << "  - #{t}\n" }

    oid = repo.write(meta, :blob)
    index.add(:path => "META.yml", :oid => oid, :mode => 0100644)

    options = {}
    options[:tree] = index.write_tree(repo)

    options[:author] = { :email => user.email, :name => user.name, :time => Time.now }
    options[:committer] = { :email => user.email, :name => user.name, :time => Time.now }
    options[:message] ||= "Initial commit"
    options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
    options[:update_ref] = 'HEAD'

    Rugged::Commit.create(repo, options)
  end

  def submit_patch(user, params)

    patch = user.patches.create!

    # make sure tags are in format: [tag1, tag2, another tag, tag3]
    # and not [tag1,tag2,another tag,tag3]
    tag_list = params[:tag_list].gsub(/,([^\s])/, ', \1').split(', ')
    origin_list = params[:origin_list].gsub(/,([^\s])/, ', \1').split(', ')

    repo = Rugged::Repository.new "./posts/#{self.id}"
    master = Rugged::Branch.lookup(repo, "master")

    builder = Rugged::Tree::Builder.new(master.tip.tree)

    body_oid = repo.write(append_whitespace(params[:body].gsub(/\r\n?/, "\n")), :blob)
    builder << { :type => :blob, :name => "#{self.category.to_s}.md", :oid => body_oid, :filemode => 0100644 }

    if self.category.to_s === 'problem' and !self.solution.blank?
      solution_oid = repo.write(append_whitespace(self.solution.gsub(/\r\n?/, "\n")), :blob)
      builder << { :type => :blob, :name => "solution.md", :oid => solution_oid, :filemode => 0100644 }
    end
    if self.category.to_s === 'question' and !self.answer.blank?
      answer_oid = repo.write(append_whitespace(self.answer.gsub(/\r\n?/, "\n")), :blob)
      builder << { :type => :blob, :name => "answer.md", :oid => answer_oid, :filemode => 0100644 }
    end

    unless params[:description].blank?
      readme_oid = repo.write(append_whitespace(params[:description].gsub(/\r\n?/, "\n")), :blob)
      builder << { :type => :blob, :name => "README.md", :oid => readme_oid, :filemode => 0100644 }
    end

      # Concatenate META attributes into one string in YAML format
      meta = "category: #{self.category.to_s}\n"
      meta << "tags:\n"
      tag_list.each { |t| meta << "  - #{t}\n" }
      meta << "origins:\n"
      origin_list.each { |t| meta << "  - #{t}\n" }

    meta_oid = repo.write(meta, :blob)
    builder << { :type => :blob, :name => "META.yml", :oid => meta_oid, :filemode => 0100644 }

    options = {}
    options[:tree] = builder.write(repo)

    options[:author] = { :email => user.email, :name => user.name, :time => Time.now }
    options[:committer] = { :email => user.email, :name => user.name, :time => Time.now }
    options[:message] ||= "Patch #{patch.id} by User #{user.id}"
    options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact

    commit = Rugged::Commit.create(repo, options)

    branch_name = patch.id.to_s

    repo.create_branch(branch_name, commit)

    patch.post_id = self.id
    patch.body = Git.bare("./posts/#{self.id}")
                .diff("#{branch_name}~", branch_name)
                .patch
    patch.save!
  end

  def commit_changes

    repo = Rugged::Repository.new "./posts/#{self.id}"
    master = Rugged::Branch.lookup(repo, "master")

    builder = Rugged::Tree::Builder.new(master.tip.tree)

    body_oid = repo.write(append_whitespace(self.body.gsub(/\r\n?/, "\n")), :blob)
    builder << { :type => :blob, :name => "#{self.category.to_s}.md", :oid => body_oid, :filemode => 0100644 }

    if self.category.to_s === 'problem' and !self.solution.blank?
      solution_oid = repo.write(append_whitespace(self.solution.gsub(/\r\n?/, "\n")), :blob)
      builder << { :type => :blob, :name => "solution.md", :oid => solution_oid, :filemode => 0100644 }
    end
    if self.category.to_s === 'question' and !self.answer.blank?
      answer_oid = repo.write(append_whitespace(self.answer.gsub(/\r\n?/, "\n")), :blob)
      builder << { :type => :blob, :name => "answer.md", :oid => answer_oid, :filemode => 0100644 }
    end

    unless self.description.blank?
      readme_oid = repo.write(append_whitespace(self.description.gsub(/\r\n?/, "\n")), :blob)
      builder << { :type => :blob, :name => "README.md", :oid => readme_oid, :filemode => 0100644 }
    end

      # Concatenate META attributes into one string in YAML format
      meta = "category: #{self.category.to_s}\n"
      meta << "tags:\n"
      self.tag_list.each { |t| meta << "  - #{t}\n" }
      meta << "origins:\n"
      self.origin_list.each { |t| meta << "  - #{t}\n" }

    meta_oid = repo.write(meta, :blob)
    builder << { :type => :blob, :name => "META.yml", :oid => meta_oid, :filemode => 0100644 }

    options = {}
    options[:tree] = builder.write(repo)

    options[:author] = { :email => self.user.email, :name => self.user.name, :time => Time.now }
    options[:committer] = { :email => self.user.email, :name => self.user.name, :time => Time.now }
    options[:message] ||= "Commit by User #{self.user.id}"
    options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
    options[:update_ref] = 'HEAD'

    Rugged::Commit.create(repo, options)
  end

  # Extend HStore API
  # Allow fetching HStore keys
  # as if they were regular columns
  #
  # Examples:
  #
  # Post.last.solution
  # Post.last.answer = 2
  # Post.last.has_answer(1)
  #
  %w[solution answer].each do |key|
    attr_accessible key
    scope "has_#{key}", lambda { |value| where("properties -> ? LIKE ?", key, value) }

    define_method(key) do
      properties && properties[key]
    end

    define_method("#{key}=") do |value|
      properties[key] = value
    end
  end

  private

  def add_to_timeline
    Timeline.create!({ user_id: self.user.id,
                       timelineable_id: id,
                       timelineable_type: self.class.to_s })
  end

  def increment_author_posts_counter
    user.increment( :posts_count ).save :validate => false
  end

  def decrement_author_posts_counter
    user.decrement( :posts_count ).save :validate => false
  end

  def validate_tags
    for tag in tag_list
      errors.add(:tag, "too long (maximum is 15 characters)") if tag.length > 15
      errors.add(:tag, "too short (minumum is 2 characters)") if tag.length < 2
    end
  end

  def validate_origins
    for tag in origin_list
      errors.add(:origin, "too long (maximum is 20 characters)") if tag.length > 20
      errors.add(:origin, "too short (minumum is 2 characters)") if tag.length < 2
    end
  end

  def append_whitespace string
    string += "\n" unless string =~ /\n\z/
    string
  end
end
