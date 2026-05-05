class AddOpenAccesstoWorkVersion < ActiveRecord::Migration[7.2]
  def change
    add_column :work_versions, :open_access, :boolean
    add_column :work_versions, :open_access_version, :string
  end
end
