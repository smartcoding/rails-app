class Timeline < ActiveRecord::Base
  attr_accessible :user_id, :timelineable_id, :timelineable_type
  belongs_to :timelineable, polymorphic: true

  def self.from_users_followed_by(user)
    where("user_id IN (?)", user.followed_user_ids)
  end
end
