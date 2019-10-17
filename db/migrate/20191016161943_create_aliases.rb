class CreateAliases < ActiveRecord::Migration[6.0]
  def change
    create_table :aliases do |t|
      t.references :creator, null: false, foreign_key: true
      t.string :display_name

      t.timestamps
    end
  end
end
