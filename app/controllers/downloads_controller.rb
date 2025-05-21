# frozen_string_literal: true

class DownloadsController < ApplicationController
  def content
    file_version = get_file_version(params[:resource_id])
    redirect_to s3_presigned_open_url(file_version), allow_other_host: true
  end

  def download
    file_version = get_file_version(params[:resource_id])
    redirect_to s3_presigned_download_url(file_version), allow_other_host: true
  end

  private

    def get_file_version(work_version_id)
      work_version = WorkVersion.find_by!(uuid: work_version_id)
      file_version = work_version.file_version_memberships.find(params[:id])
      authorize(file_version)
      file_version.file_resource.count_view! if count_view?(file_version.file_resource)
      file_version
    end

    def s3_presigned_open_url(file)
      file.file_resource.file_url(
        expires_in: ENV.fetch('DOWNLOAD_URL_TTL', 6).to_i,
        response_content_disposition: ContentDisposition.inline(file.title)
      )
    end

    def s3_presigned_download_url(file)
      file.file_resource.file_url(
        expires_in: ENV.fetch('DOWNLOAD_URL_TTL', 6).to_i,
        response_content_disposition: ContentDisposition.attachment(file.title)
      )
    end

    def count_view?(resource)
      return false if browser.bot?

      SessionViewStatsCache.call(session: session, resource: resource)
    end
end
