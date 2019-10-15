# frozen_string_literal: true

class WorkVersion < ApplicationRecord
  include AASM

  jsonb_accessor :metadata,
                 title: :string,
                 subtitle: :string,
                 keywords: [:string, array: true, default: []],
                 rights: :string,
                 description: :string,
                 resource_type: :string,
                 contributor: :string,
                 publisher: :string,
                 published_date: :string,
                 subject: :string,
                 language: :string,
                 identifier: :string,
                 based_near: :string,
                 related_url: :string,
                 source: :string

  belongs_to :work, inverse_of: :versions

  validates :title,
            presence: true

  aasm do
    state :draft, intial: true
    state :published, :withdrawn, :removed

    event :publish do
      transitions from: [:draft, :withdrawn], to: :published
    end

    event :withdraw do
      transitions from: :published, to: :withdrawn
    end

    event :remove do
      transitions from: [:draft, :withdrawn], to: :removed
    end
  end

  # Fields that can contain multiple values automatically remove blank values
  [:keywords].each do |array_field|
    define_method "#{array_field}=" do |vals|
      super(strip_blanks_from_array(vals))
    end
  end

  def display_version_name
    "Version: #{version_name.presence || version_index + 1}"
  end

  # TODO this is horrific. This should be moved into the Work for efficiency and
  # probably into a decorator/presenter with display_version_name
  def version_index
    work.versions.order(created_at: :asc).to_enum.with_index.find { |version, _index| version == self }.last || 0
  end

  private

    def strip_blanks_from_array(arr)
      Array.wrap(arr).reject(&:blank?)
    end
end
