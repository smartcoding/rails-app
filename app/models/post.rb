class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :timelines, :as => :timelineable, dependent: :destroy

  # gaining with simple_enum Gem here..
  as_enum :type, { :tip       => 1,
                   :quote     => 2,
                   :fact      => 3,
                   :problem   => 4,
                   :question  => 5 },
          :prefix => true
  validates_as_enum :type

  is_impressionable :counter_cache => { :column_name => :views_count }

  attr_accessible :body, :additional_body, :user_id, :type

  validates :body, presence: true, length: { minimum: 10 }

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

    repo = Rugged::Repository.init_at './posts/stuff', true

    oid = repo.write(self.to_s, :blob)
    index = Rugged::Index.new
    index.add(:path => "README.md", :oid => oid, :mode => 0100644)

    options = {}
    options[:tree] = index.write_tree(repo)

    options[:author] = { :email => "testuser@github.com", :name => 'Test Author', :time => Time.now }
    options[:committer] = { :email => "testuser@github.com", :name => 'Test Author', :time => Time.now }
    options[:message] ||= "Making a commit via Rugged!"
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
end
