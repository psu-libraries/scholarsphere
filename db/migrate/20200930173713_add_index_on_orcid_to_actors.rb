class AddIndexOnOrcidToActors < ActiveRecord::Migration[6.0]
  def change
    add_index :actors, :orcid, unique: true
  end
end
