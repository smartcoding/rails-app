class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments
  has_many :likes

  attr_accessible :body

  validates :body, presence: true, length: { minimum: 10 }

  def self.latest(params)
    paginate(page: params[:page], order: 'created_at DESC', per_page: 3)
  end

  def self.popular(params)
    paginate(page: params[:page], order: 'created_at DESC', per_page: 3)
  end

  def self.search(params)
    where("body LIKE ?", "%#{params[:keyword]}%").paginate(page: params[:page], order: 'created_at DESC', per_page: 3)
  end

  def self.from_users_followed_by(user)
    where("user_id IN (?)", user.followed_user_ids)
  end
end
