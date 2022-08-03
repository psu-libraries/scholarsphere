# frozen_string_literal: true

class Doi
  attr_reader :prefix,
              :suffix

  MANAGED_PREFIXES = ['10.26207', '10.18113'].freeze

  # @note If the DOI is valid from Datacite's point of view, it will be valid from our perspective, as well as have one
  # of our managed prefixes, _and_ have a particular format that the Datacite API can interpret.
  def self.valid_datacite_doi?(doi)
    formatted_doi = new(doi)

    formatted_doi.valid? && formatted_doi.managed? && doi == formatted_doi.to_datacite
  end

  # @param [String] doi
  def initialize(doi)
    @doi = begin
      URI(doi.to_s.gsub(/\s/, ''))
    rescue URI::InvalidURIError
      URI('')
    end

    parse_doi
  end

  def valid?
    prefix.to_s.match?(/^10\./) && suffix.present?
  end

  def managed?
    MANAGED_PREFIXES.include?(prefix) || prefix == ENV['DATACITE_PREFIX']
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

  def to_datacite
    "#{prefix}/#{suffix}"
  end

  private

    def parse_doi
      parsed_doi = if @doi.path
                     @doi.path.gsub(/^\//, '')
                   else
                     @doi.opaque
                   end

      @prefix, *suffixes = parsed_doi.split('/')
      @suffix = suffixes.join('/')
    end
end
