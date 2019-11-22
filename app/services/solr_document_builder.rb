# frozen_string_literal: true

class SolrDocumentBuilder
  class Error < StandardError; end

  def self.call(resource:, schema: nil)
    return {} if resource.nil?

    new(resource, schema).document
  end

  attr_reader :schema, :resource

  def initialize(resource, schema)
    raise Error, "#{resource.class} has no uuid defined" unless resource.respond_to?(:uuid)

    @resource = resource
    @schema = schema || DefaultSchema.new(resource.class).schema
  end

  def document
    HashWithIndifferentAccess.new(
      resource_document.merge(id: resource.uuid, model_ssi: resource.class.to_s)
    )
  end

  private

    def resource_document
      schema.keys.map do |solr_field|
        [solr_field.to_sym, document_values(solr_field)]
      end.to_h
    end

    def document_values(field)
      schema[field].map do |attribute|
        resource.send(attribute) if resource.respond_to?(attribute)
      end
    end
end
