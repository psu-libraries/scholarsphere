class CreateFeaturedResources < ActiveRecord::Migration[6.0]
  def change
    create_table :featured_resources do |t|
      t.uuid :resource_uuid
      t.references :resource, polymorphic: true

      t.timestamps
    end

    add_index :featured_resources,
      [:resource_uuid, :resource_type, :resource_id],
      name: 'index_featured_resources_on_uuid_and_resource',
      unique: true
  end
end
