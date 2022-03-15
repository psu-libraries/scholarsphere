class AddMintDoiToWorks < ActiveRecord::Migration[6.1]
  def change
    add_column :works, :mint_doi, :boolean, default: false
  end
end
