class AddIndexToLikes < ActiveRecord::Migration
  def self.up
    add_index :likes, [:post_id, :user_id], :name=>"index_likes_on_post_id_and_user_id", :unique => true
  end

  def self.down
    remove_index :likes, "index_likes_on_post_id_and_user_id"
  end
end
