class AddExternalAppIdToWorkVersions < ActiveRecord::Migration[6.1]
  def change
    add_reference :work_versions, :external_app, index: true, foreign_key: true, null: true
  end
end
