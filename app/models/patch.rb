class Patch < ActiveRecord::Base
  belongs_to :users
  belongs_to :posts

  attr_accessible :body

  # gaining with simple_enum Gem here..
  as_enum :status, { :pending       => 1,
                     :approved      => 2,
                     :declined      => 3 },
          # Use "is_" prefix so that category could be
          # accessed via post.is_tip? or post.is_quote!
          :prefix => 'is'
  validates_as_enum :status
end
