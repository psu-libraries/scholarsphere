class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :access_id
      t.string :email
      t.string :name
      t.string :provider
      t.string :uid

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
