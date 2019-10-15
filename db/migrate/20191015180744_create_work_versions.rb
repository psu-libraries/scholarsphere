class CreateWorkVersions < ActiveRecord::Migration[6.0]
  def change
    create_table :work_versions do |t|
      t.references :work, foreign_key: true
      t.string :version_name
      t.string :aasm_state
      t.jsonb :metadata

      t.timestamps
    end
  end
end
