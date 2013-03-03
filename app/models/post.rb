class Post < ActiveRecord::Base
  belongs_to :user
  attr_accessible :body

  validates :body, presence: true, length: { minimum: 10 }
end
