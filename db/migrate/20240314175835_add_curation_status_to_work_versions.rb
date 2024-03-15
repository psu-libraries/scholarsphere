class AddCurationStatusToWorkVersions < ActiveRecord::Migration[6.1]
  def change
    add_column :work_versions, :curation_status, :string
  end
end
