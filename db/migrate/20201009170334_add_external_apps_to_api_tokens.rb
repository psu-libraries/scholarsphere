class AddExternalAppsToApiTokens < ActiveRecord::Migration[6.0]
  def change
    add_column :api_tokens, :application_id, :integer
    add_index :api_tokens, :application_id
    add_foreign_key :api_tokens, :external_apps, column: :application_id
  end
end
