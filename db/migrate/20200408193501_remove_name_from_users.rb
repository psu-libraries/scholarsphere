class RemoveNameFromUsers < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :given_name, :string
    remove_column :users, :surname, :string
  end
end
