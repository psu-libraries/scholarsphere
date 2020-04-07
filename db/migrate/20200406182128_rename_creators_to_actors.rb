class RenameCreatorsToActors < ActiveRecord::Migration[6.0]
  def change
    delete_database

    remove_reference :work_version_creations, :creator, null: false, foreign_key: true

    rename_table :creators, :actors

    add_reference :work_version_creations, :actor, null: false, foreign_key: true
  end

  def delete_database
    execute <<~SQL
      DELETE from work_version_creations;
    SQL
  end
end
