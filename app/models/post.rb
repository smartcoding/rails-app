class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :timelines, :as => :timelineable, dependent: :destroy

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

  attr_accessible :body, :additional_body, :user_id, :category, :tag_list, :origin_list

  validates :body, presence: true, length: { minimum: 10 }

  validates :tag_list, presence: true, :length => { minimum: 1, maximum: 5 }
  validate :validate_tags
  validate :validate_origins
  validates_format_of [:origin_list, :tag_list], :with => /\A[\w\d\s\.,]+\Z/,
                      :message => 'contains wrong characters'

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

  def create_repository
    require 'rugged'

    repo = Rugged::Repository.init_at "./posts/#{self.id}", true
    index = Rugged::Index.new

    oid = repo.write(self.body, :blob)
    index.add(:path => "#{self.category.to_s}.md", :oid => oid, :mode => 0100644)

    if self.category.to_s === 'problem'
      oid = repo.write(self.additional_body, :blob)
      index.add(:path => "solution.md", :oid => oid, :mode => 0100644)
    end
    if self.category.to_s === 'question'
      oid = repo.write(self.additional_body, :blob)
      index.add(:path => "answer.md", :oid => oid, :mode => 0100644)
    end

    oid = repo.write('README file contents here', :blob)
    index.add(:path => "README.md", :oid => oid, :mode => 0100644)

    oid = repo.write("tags: [#{self.tag_list.to_s}]\norigins: [#{self.origin_list.to_s}]", :blob)
    index.add(:path => "META.yml", :oid => oid, :mode => 0100644)

    options = {}
    options[:tree] = index.write_tree(repo)

    options[:author] = { :email => "testuser@github.com", :name => 'Test Author', :time => Time.now }
    options[:committer] = { :email => "testuser@github.com", :name => 'Test Author', :time => Time.now }
    options[:message] ||= "Initial commit"
    options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
    options[:update_ref] = 'HEAD'

    Rugged::Commit.create(repo, options)
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
end
