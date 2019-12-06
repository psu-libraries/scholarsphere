class AddIndexToGroupsName < ActiveRecord::Migration[6.0]
  def change
    add_index :groups, :name
  end
end
