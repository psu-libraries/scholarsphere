class AddAdminOptionToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :admin_enabled, :boolean, default: false
  end
end
