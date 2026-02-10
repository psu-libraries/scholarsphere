class FixVersionsItemType < ActiveRecord::Migration[7.2]
  def up
    remove_column :versions, :"{null: false}" if column_exists?(:versions, :"{null: false}")
    change_column_null :versions, :item_type, false
  end

  def down
    change_column_null :versions, :item_type, true
    add_column :versions, :"{null: false}", :string unless column_exists?(:versions, :"{null: false}")
  end
end