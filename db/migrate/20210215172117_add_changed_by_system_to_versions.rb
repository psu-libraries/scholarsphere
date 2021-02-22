class AddChangedBySystemToVersions < ActiveRecord::Migration[6.0]
  def change
    add_column :versions, :changed_by_system, :boolean, null: false, default: false
  end
end
