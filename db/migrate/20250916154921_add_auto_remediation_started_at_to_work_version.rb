class AddAutoRemediationStartedAtToWorkVersion < ActiveRecord::Migration[7.2]
  def change
    add_column :work_versions, :auto_remediation_started_at, :datetime
  end
end
