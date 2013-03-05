class Like < ActiveRecord::Base
  attr_accessible :post_id

  belongs_to :post
  belongs_to :user

  validates :user_id, presence: true
  validates :post_id, presence: true

  after_save :increment_likes_counter
  after_destroy :decrement_likes_counter

  private 

  def increment_likes_counter
    Post.find( post_id ).increment( :likes_count ).save
  end

  def decrement_likes_counter
    Post.find( post_id ).decrement( :likes_count ).save
  end
end
