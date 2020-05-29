class AddDepositedAtToFileResources < ActiveRecord::Migration[6.0]
  def change
    add_column :file_resources, :deposited_at, :datetime
  end
end
