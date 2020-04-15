class CreateCollectionCreations < ActiveRecord::Migration[6.0]
  def change
    create_table :collection_creations do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: true
      t.string :alias

      t.timestamps
    end
  end
end
