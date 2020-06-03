class AddDepositedAtToWorks < ActiveRecord::Migration[6.0]
  def change
    add_column :works, :deposited_at, :datetime
  end
end
