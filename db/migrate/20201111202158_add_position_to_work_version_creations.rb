class AddPositionToWorkVersionCreations < ActiveRecord::Migration[6.0]
  def change
    add_column :work_version_creations, :position, :integer
  end
end
