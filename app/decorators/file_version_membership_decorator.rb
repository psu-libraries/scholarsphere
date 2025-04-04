# frozen_string_literal: true

class FileVersionMembershipDecorator < SimpleDelegator
  include Rails.application.routes.url_helpers

  # Method for creating the download url for a given file version
  def file_version_download_url
    wv = WorkVersion.find(work_version_id)
    URI.join(root_url, resource_download_path(id, resource_id: wv.uuid)).to_s
  end
end
