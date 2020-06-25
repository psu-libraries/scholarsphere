class CreateViewStatistics < ActiveRecord::Migration[6.0]
  def change
    create_table :view_statistics do |t|
      t.date :date, default: -> { "NOW()" }
      t.integer :count, default: 0
      t.references :resource, polymorphic: true, null: false

      t.timestamps
    end

    add_index :view_statistics, [:resource_type, :resource_id, :date]
  end
end
