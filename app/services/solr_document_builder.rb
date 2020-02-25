# frozen_string_literal: true

class SolrDocumentBuilder
  class Error < StandardError; end

  attr_reader :schemas

  def initialize(*schemas)
    @schemas = schemas
  end

  # @return [HashWithIndifferentAccess]
  def generate(resource:)
    raise Error, "#{resource.class} has no uuid defined" unless resource.respond_to?(:uuid)

    builders = schemas.map { |schema| schema.new(resource: resource) }
    base_document = HashWithIndifferentAccess.new(id: resource.uuid, model_ssi: resource.class.to_s)
    builders.map(&:document).inject(base_document, &:merge)
  end
end
