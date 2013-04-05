class AddCategoryToPosts < ActiveRecord::Migration
  def change
    # Colum names should be named like {{enum_name}}_cd
    add_column :posts, :category_cd, :integer
  end
end
