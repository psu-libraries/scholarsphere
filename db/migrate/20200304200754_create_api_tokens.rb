class CreateApiTokens < ActiveRecord::Migration[6.0]
  def change
    create_table :api_tokens do |t|
      t.string :token
      t.string :app_name
      t.string :admin_email
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :api_tokens, :token, unique: true
  end
end
