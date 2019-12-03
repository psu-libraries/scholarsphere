class AddGivenNameAndSurnameToUsers < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :name, :string

    add_column :users, :given_name, :string
    add_column :users, :surname, :string
  end
end
