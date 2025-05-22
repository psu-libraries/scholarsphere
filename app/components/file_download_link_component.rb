# frozen_string_literal: true

class FileDownloadLinkComponent < ViewComponent::Base
  def initialize(file_version_membership:, resource_id:)
    @file_version_membership = file_version_membership
    @resource_id = resource_id
  end

  def image?
    @file_version_membership.file_resource.image?
  end

  def alt_text
    @file_version_membership.file_resource.file.metadata['alt_text']
  end

  def aria_label
    download_text = t('dashboard.works.show.aria_download_file', file_name: @file_version_membership.title)

    return download_text unless image?

    download_text + t('dashboard.works.show.aria_download_image', alt_text: alt_text)
  end

  def download_path
    Rails.application.routes.url_helpers.resource_download_path(@file_version_membership.id, resource_id: @resource_id)
  end

  def download_title
    I18n.t('resources.download', name: @file_version_membership.title)
  end
end
