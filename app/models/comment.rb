class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
  has_many :timelines, :as => :timelineable

  attr_accessible :body

  validates :body, presence: true, length: { minimum: 10 }

  after_create :increment_post_comments_counter, :add_to_timeline

  private

  def increment_post_comments_counter
    Post.find( post_id ).increment( :comments_count ).save
  end

  def add_to_timeline
    Timeline.create!({ user_id: self.user.id,
                       timelineable_id: id,
                       timelineable_type: self.class.to_s })
  end
end
