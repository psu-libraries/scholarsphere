# frozen_string_literal: true

class WorkVersionCreation < ApplicationRecord
  belongs_to :work_version,
             inverse_of: :creator_aliases

  belongs_to :actor,
             inverse_of: :work_version_creations

  accepts_nested_attributes_for :actor

  validates :alias,
            presence: true

  attr_accessor :changed_by_system

  has_paper_trail(
    unless: ->(record) { record.changed_by_system },
    meta: {
      # Explicitly store the work_version_id to the PaperTrail::Version to allow
      # easy access in the work history
      work_version_id: :work_version_id
    }
  )

  def alias
    super.presence || actor&.default_alias
  end
end
