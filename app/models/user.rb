class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation,
                  :remember_me, :username, :guest

  validates_presence_of :email, :password, unless: :guest_or_provider_exist?
  validates_uniqueness_of :email, :on => :create
  validates_uniqueness_of :username, :on => :create

  before_validation :generate_username, :on => :create

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

  def to_param
    username
  end

  def your_posts(params)
    posts.paginate(page: params[:page], order: 'created_at DESC', per_page: 3)
  end

  def your_timelines(params)
    timelines.paginate(page: params[:page], order: 'created_at DESC', per_page: 3)
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

  def name
    username || "Guest"
  end

  def move_to(user)
    comments.each do |comment|
      comment.update_attributes(user_id: user.id)
      Timeline.where("timelineable_id = ? AND timelineable_type = ?",
                     comment.id, comment.class.to_s)
              .first!
              .update_attributes(user_id: user.id)
    end

    likes.each do |like|
      unless user.likes_post?(like.post) || user == like.post.user
        user.add_like_to_post!(like.post)
      end
    end

    posts.each do |post|
      post.update_attributes(user_id: user.id)
      Timeline.where("timelineable_id = ? AND timelineable_type = ?",
                     post.id, post.class.to_s)
              .first!
              .update_attributes(user_id: user.id)
    end

    relationships.each do |relationship|
      unless user.following?(relationship.followed) || relationship.followed == user
        user.follow!(relationship.followed)
      end
    end

    reverse_relationships.each do |relationship|
      unless relationship.follower.following?(user) || relationship.follower == user
        relationship.follower.follow!(user)
      end
    end
  end

  # Override Devise authentication find method to allow logging in
  # with username OR email
  def self.find_for_database_authentication(conditions={})
    self.where("username = ?", conditions[:email]).limit(1).first ||
    self.where("email = ?", conditions[:email]).limit(1).first
  end

  # Generate username if it's not provided
  def generate_username
    return unless self.username.blank?
    username = login_part = self.email.split("@").first
    num = 2
    while( !User.find_by_username(username).nil? )
      username = "#{login_part}#{num}"
      num += 2
    end
    self.username = username
  end

  def self.from_omniauth(auth)
    where(auth.slice("provider", "uid")).first || create_from_omniauth(auth)
  end

  def self.create_from_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.email = auth["info"]["nickname"] + "@github_#{Time.now.to_i}.com"
    end
  end

  protected

  def username_required?
    true if guest.nil?
  end

  def email_required?
    true if guest.nil?
  end

  def password_required?
    true if guest.nil?
  end

  private

  def guest_or_provider_exist?
    guest? || provider?
  end
end
