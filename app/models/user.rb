class User < ActiveRecord::Base
  has_many :posts
  has_many :comments
  attr_accessible :username, :password, :password_confirmation

  has_secure_password

  validates :username, presence: true, uniqueness: { case_sensitive: false },
                       length: { in: 4..12 },
                       format: { with: /^[a-z][a-z0-9]*$/,
                                 message: 'can only contain lowecase letters and numbers' }
  validates :password, length: { in: 4..8 }
  validates :password_confirmation, length: { in: 4..8 }

  def your_posts(params)
    posts.paginate(page: params[:page], order: 'created_at DESC', per_page: 3)
  end
end
