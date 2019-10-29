# frozen_string_literal: true

class Work < ApplicationRecord
  belongs_to :depositor,
             class_name: 'User',
             foreign_key: 'depositor_id',
             inverse_of: 'works'

  has_many :work_creations,
           dependent: :restrict_with_exception

  has_many :aliases,
           through: :work_creations

  has_many :access_controls,
           as: :resource,
           dependent: :destroy

  has_many :versions,
           -> { order(created_at: :desc) },
           class_name: 'WorkVersion',
           inverse_of: 'work',
           dependent: :destroy

  accepts_nested_attributes_for :versions

  module Types
    DATASET = 'dataset'

    def self.all
      [DATASET]
    end

    def self.display(type)
      type.humanize.titleize
    end

    def self.options_for_select_box
      all
        .sort
        .map { |type| [display(type), type] }
    end
  end

  validates :work_type,
            presence: true,
            inclusion: { in: Types.all }

  validates :versions,
            presence: true

  def latest_version
    versions.first
  end

  def latest_published_version
    versions.published.first
  end

  def draft_version
    versions.draft.first
  end
end
