class AddDepositedAtToCollections < ActiveRecord::Migration[6.0]
  def change
    add_column :collections, :deposited_at, :datetime
  end
end
