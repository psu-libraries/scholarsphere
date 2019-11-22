class RemoveVersionNameFromWorkVersions < ActiveRecord::Migration[6.0]
  def change
    remove_column :work_versions, :version_name, :string
  end
end
