class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
  attr_accessible :body

  validates :body, presence: true, length: { minimum: 10 }

  after_save :increment_post_comments_counter

  private

  def increment_post_comments_counter
    Post.find( post_id ).increment( :comments_count ).save
  end
end
