class ChangeCollectionWorksToProjects < ActiveRecord::Migration[6.1]
  def change
    execute <<~SQL
      UPDATE works SET work_type = 'project' WHERE work_type = 'collection'
    SQL
  end
end
