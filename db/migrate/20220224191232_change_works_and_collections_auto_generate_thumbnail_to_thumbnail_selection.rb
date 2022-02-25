class ChangeWorksAndCollectionsAutoGenerateThumbnailToThumbnailSelection < ActiveRecord::Migration[6.1]
  def change
    remove_column :works, :auto_generate_thumbnail
    remove_column :collections, :auto_generate_thumbnail
    add_column :works, :thumbnail_selection, :string
    add_column :collections, :thumbnail_selection, :string
  end
end
