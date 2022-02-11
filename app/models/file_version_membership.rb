# frozen_string_literal: true

class FileVersionMembership < ApplicationRecord
  belongs_to :work_version
  belongs_to :file_resource

  default_scope { order(title: :asc) }

  before_validation :initialize_title, on: :create

  validates :title,
            presence: true,
            uniqueness: {
              scope: :work_version_id
            }

  validate :filename_extentions_cannot_change

  delegate :size, :mime_type, :original_filename, :virus, to: :uploader

  attr_writer :changed_by_system

  has_paper_trail(
    meta: {
      # Explicitly store the work_version_id to the PaperTrail::Version to allow
      # easy access in the work history
      resource_id: :work_version_id,
      resource_type: WorkVersion.name,
      changed_by_system: :changed_by_system
    },
    skip: [:instance_token]
  )

  # Force changed_by_system to a boolean
  def changed_by_system
    !!@changed_by_system
  end

  def signature(type: 'md5')
    file_resource.file.metadata[type]
  end

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
