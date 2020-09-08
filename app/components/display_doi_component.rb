# frozen_string_literal: true

class DisplayDoiComponent < ApplicationComponent
  attr_reader :doi

  def initialize(doi:)
    @doi = Doi.new(doi) if doi.present?
  end

  def render?
    doi.present?
  end

  def css_class
    {
      valid: 'btn-primary',
      invalid: 'btn-danger',
      unmanaged: 'btn-warning'
    }[status]
  end

  def display_content
    return doi if status == :valid

    "#{status.capitalize} DOI: #{doi}"
  end

  def status
    return :invalid unless doi.valid?

    doi.managed? ? :valid : :unmanaged
  end
end
