class RenameDefaultAliasToDisplayName < ActiveRecord::Migration[6.0]
  def change
    rename_column :actors, :default_alias, :display_name
  end
end
