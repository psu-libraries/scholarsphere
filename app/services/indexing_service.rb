# frozen_string_literal: true

class IndexingService
  class Error < StandardError; end

  # @param [ActiveRecord::Base]
  # @param [Schema, Hash]
  def self.call(resource:, schema:)
    new(resource, schema).index
  end

  attr_reader :resource, :schema

  def initialize(resource, schema)
    @resource = resource
    @schema = schema
  end

  def index
    raise Error, "#{resource.class} has no uuid defined" unless resource.respond_to?(:uuid)

    Blacklight.default_index.connection.add(document.merge(id: resource.uuid, model_ssi: resource.class.to_s))
  end

  def document
    schema.keys.map do |solr_field|
      [solr_field.to_s, document_values(solr_field)]
    end.to_h
  end

  private

    def document_values(field)
      schema[field].map do |attribute|
        resource.send(attribute) if resource.respond_to?(attribute)
      end
    end
end
