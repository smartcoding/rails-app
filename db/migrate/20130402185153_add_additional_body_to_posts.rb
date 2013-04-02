class AddAdditionalBodyToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :additional_body, :text, :null => true
  end
end
