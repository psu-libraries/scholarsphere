class CreateUserGroupMemberships < ActiveRecord::Migration[6.0]
  def change
    create_table :user_group_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
