class DropAliases < ActiveRecord::Migration[6.0]
  def change
    drop_table :aliases do |t|
      t.references :creator, null: false, foreign_key: true
      t.string :display_name
      t.timestamps
    end
  end
end
