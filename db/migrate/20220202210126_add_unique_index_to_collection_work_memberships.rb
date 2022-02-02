class AddUniqueIndexToCollectionWorkMemberships < ActiveRecord::Migration[6.1]
  def change
    add_index :collection_work_memberships, [:collection_id, :work_id], unique: true
  end
end
