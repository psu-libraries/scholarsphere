class RenameAutoRemediatedVersionToRemediatedVersion < ActiveRecord::Migration[7.2]
  def change
    rename_column :file_resources, :auto_remediated_version, :remediated_version
    rename_column :work_versions, :auto_remediated_version, :remediated_version
  end
end
