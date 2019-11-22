class AddUuidToWork < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'uuid-ossp'
    add_column :works, :uuid, :uuid, default: 'uuid_generate_v4()'
  end
end
