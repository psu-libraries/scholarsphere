class AddImportedMetadataFromRmdToWorkVersions < ActiveRecord::Migration[6.1]
  def change
    add_column :work_versions, :imported_metadata_from_rmd, :boolean
  end
end
