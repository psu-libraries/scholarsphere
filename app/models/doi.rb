# frozen_string_literal: true

class Doi
  MANAGED_PREFIXES = ['10.26207', '10.18113'].freeze

  # @param [String] doi
  def initialize(doi)
    @doi = begin
             URI(doi.to_s.gsub(/\s/, ''))
           rescue URI::InvalidURIError
             URI('')
           end
  end

  def valid?
    prefix.to_s.match?(/^10\./) && suffix.present?
  end

  def managed?
    MANAGED_PREFIXES.include?(prefix) || prefix == ENV['DATACITE_PREFIX']
  end

  def prefix
    parsed_doi.split('/')[0]
  end

  def suffix
    parsed_doi.split('/')[1]
  end

  def directory_indicator
    prefix.split('.').first
  end

  def registrant_code
    prefix.gsub(/^10\./, '')
  end

  def to_s
    "doi:#{prefix}/#{suffix}"
  end

  def uri
    URI("https://doi.org/#{prefix}/#{suffix}")
  end

  private

    def parsed_doi
      if @doi.path
        @doi.path.gsub(/^\//, '')
      else
        @doi.opaque
      end
    end
end
