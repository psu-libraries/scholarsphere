class AddRemediationStartedAtToWorkVersion < ActiveRecord::Migration[7.2]
  def change
    add_column :work_versions, :remediation_started_at, :datetime
  end
end
