class Like < ActiveRecord::Base
  attr_accessible :post_id

  belongs_to :post
  belongs_to :user

  has_many :timelines, :as => :timelineable

  validates :user_id, presence: true
  validates :post_id, presence: true

  after_create :increment_likes_counter, :add_to_timeline
  after_destroy :decrement_likes_counter

  private 

  def increment_likes_counter
    Post.find( post_id ).increment( :likes_count ).save
  end

  def decrement_likes_counter
    Post.find( post_id ).decrement( :likes_count ).save
  end

  def add_to_timeline
    Timeline.create!({ user_id: user_id,
                       timelineable_id: id,
                       timelineable_type: self.class.to_s })
  end
end
