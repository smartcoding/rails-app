class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments
  attr_accessible :body

  validates :body, presence: true, length: { minimum: 10 }

  def self.latest(params)
    paginate(page: params[:page], order: 'created_at DESC', per_page: 3)
  end

  def self.search(params)
    where("body LIKE ?", "%#{params[:keyword]}%").paginate(page: params[:page], order: 'created_at DESC', per_page: 3)
  end

  def self.from_users_followed_by(user)
    followed_user_ids = user.followed_user_ids
    where("user_id IN (?) OR user_id = ?", followed_user_ids, user)
  end
end
