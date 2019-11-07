# frozen_string_literal: true

class IndexingService
  class Error < StandardError; end

  # @param [ActiveRecord::Base]
  # @param [Schema, Hash, nil]
  # @param [Boolean]
  def self.call(resource:, schema: nil, commit: false)
    new(resource, schema, commit).index
  end

  attr_reader :resource, :schema

  def initialize(resource, schema, commit)
    @resource = resource
    @schema = schema || DefaultSchema.new(resource.class).schema
    @commit = commit
  end

  def index
    raise Error, "#{resource.class} has no uuid defined" unless resource.respond_to?(:uuid)

    connection.add(document.merge(id: resource.uuid, model_ssi: resource.class.to_s))
    connection.commit if commit?
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

    def commit?
      @commit
    end

    def connection
      @connection ||= Blacklight.default_index.connection
    end
end
