class Patch < ActiveRecord::Base
  belongs_to :users
  belongs_to :posts

  attr_accessible :body

  # gaining with simple_enum Gem here..
  as_enum :status, { :pending       => 1,
                     :merged        => 2,
                     :declined      => 3 },
          # Use "is_" prefix so that status could be
          # accessed via patch.is_approved? or post.is_declined!
          :prefix => 'is'

  before_save :set_defaults

  private

  def set_defaults
    self.status = :pending if self.status.nil?
  end
end
