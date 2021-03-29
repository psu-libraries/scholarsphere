# frozen_string_literal: true

class Doi
  attr_reader :prefix,
              :suffix

  MANAGED_PREFIXES = ['10.26207', '10.18113'].freeze

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
