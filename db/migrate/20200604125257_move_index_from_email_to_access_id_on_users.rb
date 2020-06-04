class MoveIndexFromEmailToAccessIdOnUsers < ActiveRecord::Migration[6.0]
  def change
    remove_index :users, :email
    add_index :users, :access_id, unique: true
  end
end
