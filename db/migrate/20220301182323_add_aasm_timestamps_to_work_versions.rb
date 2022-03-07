class AddAasmTimestampsToWorkVersions < ActiveRecord::Migration[6.1]
  def change
    add_column :work_versions, :published_at, :datetime
    add_column :work_versions, :withdrawn_at, :datetime
    add_column :work_versions, :removed_at, :datetime
  end
end
