class CreateCollectionWorkMemberships < ActiveRecord::Migration[6.0]
  def change
    create_table :collection_work_memberships do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :work, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end
  end
end
