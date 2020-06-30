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
end
