class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
  attr_accessible :body

  validates :body, presence: true, length: { minimum: 10 }
end
