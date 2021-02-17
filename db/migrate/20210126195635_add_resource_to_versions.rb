class AddResourceToVersions < ActiveRecord::Migration[6.0]
  def change
    add_column :versions, :resource_id, :integer
    add_column :versions, :resource_type, :string
    add_index :versions, [:resource_type, :resource_id]
  end
end
