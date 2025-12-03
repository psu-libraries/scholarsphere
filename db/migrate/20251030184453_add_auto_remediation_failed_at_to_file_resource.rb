class AddAutoRemediationFailedAtToFileResource < ActiveRecord::Migration[7.2]
  def change
    add_column :file_resources, :auto_remediation_failed_at, :datetime
  end
end
