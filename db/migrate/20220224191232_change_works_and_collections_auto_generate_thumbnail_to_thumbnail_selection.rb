class ChangeWorksAndCollectionsAutoGenerateThumbnailToThumbnailSelection < ActiveRecord::Migration[6.1]
  def up
    add_column :works, :thumbnail_selection, :string, default: 'default_icon'
    add_column :collections, :thumbnail_selection, :string, default: 'default_icon'

    execute "UPDATE works SET thumbnail_selection = 'auto_generated' WHERE auto_generate_thumbnail = true"
    execute "UPDATE collections SET thumbnail_selection = 'auto_generated' WHERE auto_generate_thumbnail = true"

    remove_column :works, :auto_generate_thumbnail, :boolean
    remove_column :collections, :auto_generate_thumbnail, :boolean
  end

  def down
    add_column :works, :auto_generate_thumbnail, :boolean, default: false
    add_column :collections, :auto_generate_thumbnail, :boolean, default: false

    execute "UPDATE works SET auto_generate_thumbnail = true WHERE thumbnail_selection = 'auto_generated'"
    execute "UPDATE collections SET auto_generate_thumbnail = true WHERE thumbnail_selection = 'auto_generated'"

    remove_column :works, :thumbnail_selection, :string
    remove_column :collections, :thumbnail_selection, :string
  end
end
