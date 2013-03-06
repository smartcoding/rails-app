class CreateTimelines < ActiveRecord::Migration
  def change
    create_table :timelines do |t|
      t.integer :user_id
      t.integer :timelineable_id
      t.string :timelineable_type

      t.timestamps
    end
  end
end
