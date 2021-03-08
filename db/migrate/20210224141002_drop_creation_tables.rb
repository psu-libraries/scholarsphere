class DropCreationTables < ActiveRecord::Migration[6.0]
  def change
    drop_table :collection_creations
    drop_table :work_version_creations
  end
end
