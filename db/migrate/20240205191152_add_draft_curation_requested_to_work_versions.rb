class AddDraftCurationRequestedToWorkVersions < ActiveRecord::Migration[6.1]
  def change
    add_column :work_versions, :draft_curation_requested, :boolean
  end
end
