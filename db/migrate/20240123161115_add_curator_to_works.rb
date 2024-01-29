class AddCuratorToWorks < ActiveRecord::Migration[6.1]
  def change
    add_column :works, :curator_id, :integer
    add_foreign_key :works, :users, column: :curator_id
  end
end
