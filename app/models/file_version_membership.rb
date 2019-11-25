# frozen_string_literal: true

class FileVersionMembership < ApplicationRecord
  belongs_to :work_version
  belongs_to :file_resource

  before_validation :initialize_title, on: :create

  validates :title,
            presence: true,
            uniqueness: {
              scope: :work_version_id
            }

  validate :filename_extentions_cannot_change

  delegate :size, :mime_type, :original_filename, to: :uploader

  attr_accessor :changed_by_system

  has_paper_trail(
    unless: ->(record) { record.changed_by_system },
    meta: {
      # Explicitly store the work_version_id to the PaperTrail::Version to allow
      # easy access in the work history
      work_version_id: :work_version_id
    }
  )

  private

    def uploader
      @uploader ||= file_resource&.file
    end

    def initialize_title
      self.title ||= uploader&.original_filename
    end

    def filename_extentions_cannot_change
      return if title.blank? || File.extname(title) == File.extname(original_filename)

      errors.add(:title, :different_extension, original: original_filename)
    end
end
