class RenameAutoRemediatedVersionToRemediatedVersion < ActiveRecord::Migration[7.2]
  def up
    rename_column :file_resources, :auto_remediated_version, :remediated_version
    rename_column :work_versions, :auto_remediated_version, :remediated_version

    change_column_default :work_versions, :remediated_version, from: nil, to: false
    change_column_null :work_versions, :remediated_version, false, false
  end

  def down
    change_column_null :work_versions, :remediated_version, true
    change_column_default :work_versions, :remediated_version, from: false, to: nil

    rename_column :work_versions, :remediated_version, :auto_remediated_version
    rename_column :file_resources, :remediated_version, :auto_remediated_version
  end
end
