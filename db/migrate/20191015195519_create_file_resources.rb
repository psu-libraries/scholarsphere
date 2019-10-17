class CreateFileResources < ActiveRecord::Migration[6.0]
  def change
    create_table :file_resources do |t|
      t.jsonb :file_data

      t.timestamps
    end
  end
end
