# frozen_string_literal: true

class DownloadsController < ApplicationController
  def content
    work_version = WorkVersion.find_by!(uuid: download_params[:resource_id])
    file_version = work_version.file_version_memberships.find(download_params[:id])
    authorize(file_version)
    file_version.file_resource.count_view! if count_view?(file_version.file_resource)

    remediation_service = AutoRemediateService.new(work_version.id, current_user.admin?, file_version.file_resource.pdf?)
    remediation_service.call if remediation_service.able_to_auto_remediate? && download_params[:download]

    redirect_to s3_presigned_url(file_version, download: download_params[:download]), allow_other_host: true
  end

  private

    def s3_presigned_url(file, download: false)
      content_disposition = download ? ContentDisposition.attachment(file.title) : ContentDisposition.inline(file.title)
      file.file_resource.file_url(
        expires_in: ENV.fetch('DOWNLOAD_URL_TTL', 6).to_i,
        response_content_disposition: content_disposition
      )
    end

    def count_view?(resource)
      return false if browser.bot?

      SessionViewStatsCache.call(session: session, resource: resource)
    end

    def download_params
      params[:download] = ActiveModel::Type::Boolean.new.cast(params[:download])
      params.permit(:id, :resource_id, :download)
    end
end
