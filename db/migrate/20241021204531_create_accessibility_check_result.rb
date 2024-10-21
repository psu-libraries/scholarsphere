class CreateAccessibilityCheckResult < ActiveRecord::Migration[6.1]
  def change
    create_table :accessibility_check_results do |t|
      t.references :file_resource, foreign_key: true
      t.jsonb :report, null: false, default: { error: 'No report available' }

      t.timestamps
    end
  end
end
