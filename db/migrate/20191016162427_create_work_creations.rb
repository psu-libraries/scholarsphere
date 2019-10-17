class CreateWorkCreations < ActiveRecord::Migration[6.0]
  def change
    create_table :work_creations do |t|
      t.references :alias, null: false, foreign_key: true
      t.references :work, null: false, foreign_key: true

      t.timestamps
    end
  end
end
