class Timeline < ActiveRecord::Base
  attr_accessible :user_id, :timelineable_id, :timelineable_type
  belongs_to :timelineable, polymorphic: true
end
