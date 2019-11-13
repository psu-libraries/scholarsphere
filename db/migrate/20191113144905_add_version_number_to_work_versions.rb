class AddVersionNumberToWorkVersions < ActiveRecord::Migration[6.0]
  def change
    add_column :work_versions, :version_number, :int, null: false
  end
end
