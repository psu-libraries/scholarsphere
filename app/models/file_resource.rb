# frozen_string_literal: true

class FileResource < ApplicationRecord
  include FileUploader::Attachment(:file)

  has_many :file_version_memberships, dependent: :destroy
  has_many :work_versions, through: :file_version_memberships
end
