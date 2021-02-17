# frozen_string_literal: true

# @abstract Class for parsing and validating ORCiD ids. Accepts either a numeric or formatted string, as well as a URI,
# and can return any of those formats. The unformatted numeric string is preferred for database storage, but this
# class be used to present the id in alternative, human-readable formats.

class OrcidId
  def self.valid?(value)
    new(value).valid?
  end

  attr_reader :id

  # @param [String, URI] id
  def initialize(id)
    @id = URI(id.to_s).path.gsub(/^\//, '').delete('-')
  end

  def valid?
    id.match?(/^\d{15,15}[0-9X]$/)
  end

  def to_s
    id
  end

  def to_human
    id.gsub(/(\d{4})(?!$)/, '\1-')
  end

  def uri
    URI("https://orcid.org/#{to_human}")
  end
end
