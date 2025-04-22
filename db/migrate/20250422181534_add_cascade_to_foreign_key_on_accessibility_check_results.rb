class AddCascadeToForeignKeyOnAccessibilityCheckResults < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :accessibility_check_results, :file_resources
    add_foreign_key :accessibility_check_results, :file_resources, on_delete: :cascade
  end
end
