class CreateLegacyIdentifiers < ActiveRecord::Migration[6.0]
  def change
    create_table :legacy_identifiers do |t|
      t.integer :version
      t.string :old_id
      t.references :resource, polymorphic: true, null: false

      t.timestamps
    end

    add_index :legacy_identifiers, %i[version old_id], unique: true
  end
end
