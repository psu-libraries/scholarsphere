class UpdatePsuidIndexOnActors < ActiveRecord::Migration[6.0]
  def change
    remove_index :actors, :psu_id
    add_index :actors, :psu_id, unique: true
  end
end
