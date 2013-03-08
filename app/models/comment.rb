class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
  has_many :timelines, :as => :timelineable, dependent: :destroy

  attr_accessible :body

  validates :body, presence: true, length: { minimum: 10 }

  after_create :increment_post_comments_counter,
               :increment_user_comments_counter
               :add_to_timeline
  after_destroy :decrement_post_comments_counter,
                :decrement_user_comments_counter

  private

  def increment_post_comments_counter
    post.increment( :comments_count ).save
  end
  def decrement_post_comments_counter
    post.decrement( :comments_count ).save :validate => false
  end

  def add_to_timeline
    Timeline.create!({ user_id: self.user.id,
                       timelineable_id: id,
                       timelineable_type: self.class.to_s })
  end

  def increment_user_comments_counter
    user.increment( :comments_count ).save :validate => false
  end
  def decrement_user_comments_counter
    user.decrement( :comments_count ).save :validate => false
  end
end
