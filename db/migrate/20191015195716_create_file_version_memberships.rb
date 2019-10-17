class CreateFileVersionMemberships < ActiveRecord::Migration[6.0]
  def change
    create_table :file_version_memberships do |t|
      t.references :work_version, null: false, foreign_key: true
      t.references :file_resource, null: false, foreign_key: true
      t.string :title

      t.timestamps
    end
  end
end
