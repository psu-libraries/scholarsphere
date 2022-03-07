# frozen_string_literal: true

class DownloadsController < ApplicationController
  def content
    work_version = WorkVersion.find_by!(uuid: params[:resource_id])
    file_version = work_version.file_version_memberships.find(params[:id])
    authorize(file_version)
    file_version.file_resource.count_view! if count_view?(file_version.file_resource)
    redirect_to s3_presigned_url(file_version)
  end

  private

    def s3_presigned_url(file)
      file.file_resource.file_url(
        expires_in: ENV.fetch('DOWNLOAD_URL_TTL', 6).to_i,
        response_content_disposition: ContentDisposition.inline(file.title)
      )
    end

    def count_view?(resource)
      return false if browser.bot?

      SessionViewStatsCache.call(session: session, resource: resource)
    end
end
