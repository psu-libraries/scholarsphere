class AddDefaultAliasToCreators < ActiveRecord::Migration[6.0]
  def change
    add_column :creators, :default_alias, :string
    add_index :creators, :psu_id
  end
end
