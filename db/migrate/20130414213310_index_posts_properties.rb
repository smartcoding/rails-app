class IndexPostsProperties < ActiveRecord::Migration
  def up
    execute "CREATE INDEX posts_properties ON posts USING GIN(properties)"
  end

  def down
    execute "DROP INDEX posts_properties"
  end
end
