class UpdateNameIndexOnGroups < ActiveRecord::Migration[6.0]
  def change
    remove_index :groups, :name
    add_index :groups, :name, unique: true
  end
end
