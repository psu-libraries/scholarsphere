class AddIndexOnTitleToFileVersionMemberships < ActiveRecord::Migration[6.0]
  def change
    add_index :file_version_memberships, [:work_version_id, :title], unique: true
  end
end
