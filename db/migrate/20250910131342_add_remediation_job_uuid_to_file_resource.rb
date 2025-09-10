class AddRemediationJobUuidToFileResource < ActiveRecord::Migration[7.2]
  def change
    add_column :file_resources, :remediation_job_uuid, :string
  end
end
