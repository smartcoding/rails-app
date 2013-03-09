class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :timelines, dependent: :destroy
  has_many :likes, dependent: :destroy

  has_many :relationships, foreign_key: "follower_id", dependent: :destroy
  has_many :followed_users, through: :relationships, source: :followed

  has_many :reverse_relationships, foreign_key: "followed_id",
                                   class_name: "Relationship",
                                   dependent: :destroy
  has_many :followers, through: :reverse_relationships, source: :follower

  def your_posts(params)
    posts.paginate(page: params[:page], order: 'created_at DESC', per_page: 3)
  end

  def your_timelines(params)
    timelines.paginate(page: params[:page], order: 'created_at DESC', per_page: 3)
  end

  def following_feed(params)
    Post.from_users_followed_by(self).paginate(page: params[:page], order: 'created_at DESC', per_page: 3)
  end

  def following?(other_user)
    self.relationships.find_by_followed_id(other_user.id)
  end

  def follow!(other_user)
    self.relationships.create!(followed_id: other_user.id)
  end
  def unfollow!(other_user)
    self.relationships.find_by_followed_id(other_user.id).destroy
  end

  def add_like_to_post!(post)
    self.likes.create!(post_id: post.id)
  end
  def unlike_a_post!(post)
    self.likes.find_by_post_id(post.id).destroy
  end
  def likes_post?(post)
    self.likes.find_by_post_id post.id
  end

  def flow_feed(params)
    Timeline.from_users_followed_by(self).paginate(page: params[:page], order: 'created_at DESC', per_page: 3)
  end
end
