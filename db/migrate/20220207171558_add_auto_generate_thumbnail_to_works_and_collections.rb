class AddAutoGenerateThumbnailToWorksAndCollections < ActiveRecord::Migration[6.1]
  def change
    add_column :works, :auto_generate_thumbnail, :boolean, default: false
    add_column :collections, :auto_generate_thumbnail, :boolean, default: false
  end
end
