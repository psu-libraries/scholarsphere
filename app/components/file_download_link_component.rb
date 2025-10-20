# frozen_string_literal: true

class FileDownloadLinkComponent < ViewComponent::Base
  def initialize(file_version_membership:)
    @file_version_membership = file_version_membership
  end

  def alt_text
    @file_version_membership.file_resource.file.metadata['alt_text']
  end

  def aria_label(download: true)
    text = if download == true
             t('dashboard.works.show.aria_download_file',
               file_name: @file_version_membership.title)
           else
             t('dashboard.works.show.aria_view_file',
               file_name: @file_version_membership.title)
           end

    return text unless image?

    text + t('dashboard.works.show.aria_download_image',
             alt_text: alt_text)
  end

  def download_path(download: true)
    Rails.application
      .routes.url_helpers
      .resource_download_path(@file_version_membership.id,
                              resource_id: work_version_uuid,
                              download: download)
  end

  def view_title
    I18n.t('resources.view',
           name: @file_version_membership.title)
  end

  def download_title
    I18n.t('resources.download',
           name: @file_version_membership.title)
  end

  def remediation_alert?
    remediation_service = AutoRemediateService.new(work_version_id, helpers.current_user.admin?, pdf?)
    remediation_service.able_to_auto_remediate?
  end

  def under_review_notice
    if work.under_manual_review
      I18n.t('dashboard.works.show.under_review_notice')
    end
  end

  private

    def image?
      @file_version_membership.file_resource.image?
    end

    def can_remediate?
      @file_version_membership.file_resource.can_remediate?
    end

    def work_version_uuid
      @file_version_membership.work_version.uuid
    end

    def work_version_id
      @file_version_membership.work_version.id
    end

    def work
      @file_version_membership.work_version.work
    end
end
