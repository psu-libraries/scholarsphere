class AddDoiToWorksAndWorkVersions < ActiveRecord::Migration[6.0]
  def change
    add_column :works, :doi, :string
    add_column :work_versions, :doi, :string
  end
end
