class AddPositionToCollectionCreations < ActiveRecord::Migration[6.0]
  def change
    add_column :collection_creations, :position, :integer
  end
end
