class CreatePatches < ActiveRecord::Migration
  def change
    create_table :patches do |t|
      t.references :user
      t.references :post

      t.text :body
      t.integer :status_cd

      t.timestamps
    end
  end
end
