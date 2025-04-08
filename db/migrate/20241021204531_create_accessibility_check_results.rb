class CreateAccessibilityCheckResults < ActiveRecord::Migration[6.1]
  def change
    create_table :accessibility_check_results do |t|
      t.jsonb :detailed_report, null: false
      t.references :file_resource, null: false, foreign_key: true, unique: true

      t.timestamps
    end

  end
end
