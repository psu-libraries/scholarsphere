# frozen_string_literal: true

class Orcid
  def self.valid?(value)
    new(value).valid?
  end

  # @param [String] id
  def initialize(id)
    @id = URI(id.gsub(/\s/, ''))
  end

  def valid?
    parsed_id.match?(/^\d{4,4}-\d{4,4}-\d{4,4}-\d{4,4}$/)
  end

  def to_s
    "https://orcid.org/#{parsed_id}"
  end

  def uri
    URI(to_s)
  end

  private

    def parsed_id
      if @id.path
        @id.path.gsub(/^\//, '')
      else
        @id.opaque
      end
    end
end
