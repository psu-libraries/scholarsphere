class AddAutoRemediatedVersionToWorkVersion < ActiveRecord::Migration[7.2]
  def change
    add_column :work_versions, :auto_remediated_version, :boolean
  end
end
