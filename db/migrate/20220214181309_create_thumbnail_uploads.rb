class CreateThumbnailUploads < ActiveRecord::Migration[6.1]
  def change
    create_table :thumbnail_uploads do |t|
      t.references :resource, polymorphic: true
      t.references :file_resource, null: false, foreign_key: true, unique: true

      t.timestamps
    end

    add_index :thumbnail_uploads,
              [:resource_type, :resource_id],
              name: 'index_thumbnail_uploads_on_type_and_resource_id',
              unique: true
  end
end
