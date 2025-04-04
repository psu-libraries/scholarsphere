class AddAccessibilityRemediationRequestedToWorkVersions < ActiveRecord::Migration[6.1]
  def change
    add_column :work_versions, :accessibility_remediation_requested, :boolean
  end
end
