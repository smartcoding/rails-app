class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments
  has_many :likes
  has_many :timelines, :as => :timelineable

  is_impressionable :counter_cache => { :column_name => :views_count }

  attr_accessible :body

  validates :body, presence: true, length: { minimum: 10 }

  after_create :add_to_timeline

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

  private

  def add_to_timeline
    Timeline.create!({ user_id: self.user.id,
                       timelineable_id: id,
                       timelineable_type: self.class.to_s })
  end
end
