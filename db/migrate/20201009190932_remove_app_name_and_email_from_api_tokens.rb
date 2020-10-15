class RemoveAppNameAndEmailFromApiTokens < ActiveRecord::Migration[6.0]
  def change
    remove_column :api_tokens, :app_name
    remove_column :api_tokens, :admin_email
  end
end
