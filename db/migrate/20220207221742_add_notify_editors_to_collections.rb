class AddNotifyEditorsToCollections < ActiveRecord::Migration[6.1]
  def change
    add_column :collections, :notify_editors, :boolean, default: false
  end
end
