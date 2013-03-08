class AddFollowingCountToUsers < ActiveRecord::Migration
  def change
    add_column :users, :following_count, :integer, :default => 0
  end
end
