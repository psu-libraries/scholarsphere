# frozen_string_literal: true

class DownloadsController < ApplicationController
  before_action only: :content do |controller|
    BotChallengePage::BotChallengePageController.bot_challenge_enforce_filter(controller, immediate: true)
  end

  def content
    work_version = WorkVersion.find_by!(uuid: download_params[:resource_id])
    file_version = work_version.file_version_memberships.find(download_params[:id])
    download_requested = valid_download_token?(download_params[:download_token], file_version.id)

    authorize(file_version)
    file_version.file_resource.count_view! if count_view?(file_version.file_resource)

    remediation_service = PdfRemediation::AutoRemediateService.new(
      work_version.id,
      current_user,
      file_version.file_resource.can_remediate?
    )
    remediation_service.call if remediation_service.able_to_auto_remediate? && download_requested

    redirect_to s3_presigned_url(file_version, download: download_requested), allow_other_host: true
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

    def valid_download_token?(token, file_version_id)
      return false if token.blank?

      token_file_version_id = download_token_verifier.verify(token, purpose: :download_request)
      token_file_version_id.to_i == file_version_id.to_i
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      false
    end

    def download_token_verifier
      Rails.application.message_verifier(:download_request_token)
    end

    def download_params
      params.permit(:id, :resource_id, :download_token)
    end
end
