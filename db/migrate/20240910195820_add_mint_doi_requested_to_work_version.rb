class AddMintDoiRequestedToWorkVersion < ActiveRecord::Migration[6.1]
  def change
    add_column :work_versions, :mint_doi_requested, :boolean
  end
end
