class AddDefaultToCollectionsUuid < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'uuid-ossp'
    change_column_default :collections, :uuid, from: nil, to: 'uuid_generate_v4()'
  end
end
