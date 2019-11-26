class AddWorkVersionIdToVersions < ActiveRecord::Migration[6.0]
  def change
    add_column :versions, :work_version_id, :integer
    add_index :versions, :work_version_id
  end
end
