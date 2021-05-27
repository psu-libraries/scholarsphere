class AddUuidToFileResource < ActiveRecord::Migration[6.1]
  def change
    enable_extension 'uuid-ossp'
    add_column :file_resources, :uuid, :uuid, default: 'uuid_generate_v4()'
  end
end

