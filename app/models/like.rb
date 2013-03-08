class Like < ActiveRecord::Base
  attr_accessible :post_id

  belongs_to :post
  belongs_to :user

  has_many :timelines, :as => :timelineable

  validates :user_id, presence: true
  validates :post_id, presence: true

  after_create :increment_post_likes_counter,
               :increment_user_likes_counter,
               :add_to_timeline
  after_destroy :decrement_post_likes_counter,
                :decrement_user_likes_counter

  private 

  def increment_post_likes_counter
    post.increment( :likes_count ).save
  end

  def decrement_post_likes_counter
    post.decrement( :likes_count ).save
  end

  def add_to_timeline
    Timeline.create!({ user_id: user_id,
                       timelineable_id: id,
                       timelineable_type: self.class.to_s })
  end

  def increment_user_likes_counter
    user.increment( :likes_count ).save :validate => false
  end

  def decrement_user_likes_counter
    user.decrement( :likes_count ).save :validate => false
  end
end
