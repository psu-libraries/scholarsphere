class CreateCollections < ActiveRecord::Migration[6.0]
  def change
    create_table :collections do |t|
      t.references :depositor, null: false, foreign_key: { to_table: :actors }
      t.uuid :uuid
      t.string :doi
      t.jsonb :metadata

      t.timestamps
    end
  end
end
