class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments
  attr_accessible :body

  validates :body, presence: true, length: { minimum: 10 }

  def self.latest(params)
    paginate(page: params[:page], order: 'created_at DESC', per_page: 3)
  end
end
