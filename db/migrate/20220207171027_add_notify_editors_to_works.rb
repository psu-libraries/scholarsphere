class AddNotifyEditorsToWorks < ActiveRecord::Migration[6.1]
  def change
    add_column :works, :notify_editors, :boolean, default: false
  end
end
