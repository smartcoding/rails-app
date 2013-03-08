class Relationship < ActiveRecord::Base
  attr_accessible :followed_id

  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"
  has_many :timelines, :as => :timelineable, dependent: :destroy

  validates :follower_id, presence: true
  validates :followed_id, presence: true

  after_create :add_to_timeline,
               :increment_follower_count,
               :increment_followed_count
  after_destroy :decrement_follower_count,
                :decrement_followed_count

  private 

  def add_to_timeline
    Timeline.create!({ user_id: follower_id,
                       timelineable_id: id,
                       timelineable_type: self.class.to_s })
  end

  def increment_follower_count
    follower.increment(:following_count).save :validate => false
  end
  def decrement_follower_count
    follower.decrement(:following_count).save :validate => false
  end

  def increment_followed_count
    followed.increment(:followers_count).save :validate => false
  end
  def decrement_followed_count
    followed.decrement(:followers_count).save :validate => false
  end
end
