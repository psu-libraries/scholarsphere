# frozen_string_literal: true

class RenameOpenAccessToOpenAccessUploadOnWorkVersions < ActiveRecord::Migration[7.2]
  def change
    rename_column :work_versions, :open_access, :open_access_upload
  end
end
