class CreateWorkVersionCreations < ActiveRecord::Migration[6.0]
  def change
    create_table :work_version_creations do |t|
      t.references :work_version, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: true
      t.string :alias

      t.timestamps
    end
  end
end
