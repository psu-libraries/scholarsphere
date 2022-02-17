class CreateThumbnailUploads < ActiveRecord::Migration[6.1]
  def change
    create_table :thumbnail_uploads do |t|
      t.references :resource, polymorphic: true, null: false, index: {unique: true}
      t.references :file_resource, null: false, foreign_key: true, index: {unique: true}

      t.timestamps
    end
  end
end
