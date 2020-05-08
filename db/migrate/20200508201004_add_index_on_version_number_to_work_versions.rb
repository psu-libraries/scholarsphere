class AddIndexOnVersionNumberToWorkVersions < ActiveRecord::Migration[6.0]
  def change
    add_index :work_versions, [:work_id, :version_number], unique: true
  end
end
