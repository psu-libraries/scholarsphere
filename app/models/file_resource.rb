# frozen_string_literal: true

class FileResource < ApplicationRecord
  include FileUploader::Attachment(:file)
  include DepositedAtTimestamp
  include ViewStatistics

  has_many :file_version_memberships, dependent: :destroy
  has_many :work_versions, through: :file_version_memberships

  has_many :legacy_identifiers,
           as: :resource,
           dependent: :destroy

  # @note Using `head_object` will retrieve the metadata without retriving the entire object.
  def etag
    @etag ||= client
      .head_object(bucket: ENV['AWS_BUCKET'], key: "#{file_data['storage']}/#{file_data['id']}")
      .etag
      .gsub('"', '')
  rescue Aws::S3::Errors::Forbidden
    '[unavailable]'
  end

  private

    def client
      @client ||= Aws::S3::Client.new
    end
end
