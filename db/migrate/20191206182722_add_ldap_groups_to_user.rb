class AddLdapGroupsToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :ldap_groups, :jsonb, array: true, default: []
  end
end
