# frozen_string_literal: true

class DisplayDoiComponent < ApplicationComponent
  attr_reader :raw_doi,
              :doi

  def initialize(doi:)
    @raw_doi = doi
    @doi = Doi.new(doi) if doi.present?
  end

  def render?
    doi.present?
  end

  def css_class
    {
      valid: 'text-primary',
      invalid: 'text-danger',
      unmanaged: 'text-secondary'
    }[status]
  end

  def tooltip
    I18n.t("resources.doi.#{status}")
  end

  def status
    return :invalid unless doi.valid?

    doi.managed? ? :valid : :unmanaged
  end
end
