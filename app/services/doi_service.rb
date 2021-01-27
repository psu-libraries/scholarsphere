# frozen_string_literal: true

require 'data_cite'

module DoiService
  class Error < StandardError; end

  def self.call(resource, client_source: nil, metadata_source: nil)
    strategy_class = [WorkAndVersionStrategy, CollectionStrategy].find { |klass| klass.applicable_to?(resource) }

    raise ArgumentError, "DoiService cannot be called with a #{resource.class.name}" if strategy_class.blank?
    raise Error.new("Cannot mint a doi for an invalid resource: #{resource.inspect}") unless resource.valid?

    instance = strategy_class.new(resource)
    instance.client_source = client_source
    instance.metadata_source = metadata_source
    instance.call
  end

  def self.publish_doi(doi:, metadata_adapter:, client:)
    metadata = metadata_adapter
      .tap(&:validate!)
      .attributes

    response_doi, _response_metadata = client.publish(
      doi: doi,
      metadata: metadata
    )

    response_doi
  end

  class WorkAndVersionStrategy
    attr_reader :resource,
                :work_version

    attr_writer :client_source,
                :metadata_source

    def self.applicable_to?(obj)
      obj.is_a?(Work) || obj.is_a?(WorkVersion)
    end

    def initialize(resource)
      unless self.class.applicable_to?(resource)
        raise ArgumentError, "#{self.class.name} expects resource to be a Work or WorkVersion"
      end

      # resource is the object that will receive the doi
      @resource = resource

      # work_version is the object that will provide the metadata to DataCite
      @work_version = if resource.is_a? WorkVersion
                        resource
                      elsif resource.is_a? Work
                        resource.latest_version
                      end
    end

    def call
      has_doi_already = resource.doi.present?
      is_draft = work_version.draft?

      case
      when !has_doi_already && is_draft
        doi = register_new_doi
        resource.update!(doi: doi)
      when !has_doi_already && !is_draft
        doi = publish_doi(doi: nil)
        resource.update!(doi: doi)
      when has_doi_already && is_draft
        # No-op
      when has_doi_already && !is_draft
        publish_doi(doi: resource.doi)
        # No need to update resource
      end
    end

    def client_source
      @client_source ||= DataCite::Client.public_method(:new)
    end

    def metadata_source
      @metadata_source ||= DataCite::Metadata::WorkVersion.public_method(:new)
    end

    private

      def register_new_doi
        response_doi, _response_metadata = client_source.call.register
        response_doi
      end

      def publish_doi(doi:)
        metadata_adapter = metadata_source
          .call(resource: work_version, public_identifier: resource.uuid)

        client = client_source.call

        DoiService.publish_doi(doi: doi, metadata_adapter: metadata_adapter, client: client)
      end
  end

  class CollectionStrategy
    attr_reader :collection

    attr_writer :client_source,
                :metadata_source

    def self.applicable_to?(obj)
      obj.is_a? Collection
    end

    def initialize(collection)
      unless self.class.applicable_to?(collection)
        raise ArgumentError, "#{self.class.name} expects resource to be a Collection"
      end

      @collection = collection
    end

    def call
      if collection.doi.present?
        publish_doi(doi: collection.doi)
      else
        new_doi = publish_doi(doi: nil)
        collection.update!(doi: new_doi)
      end
    end

    def client_source
      @client_source ||= DataCite::Client.public_method(:new)
    end

    def metadata_source
      @metadata_source ||= DataCite::Metadata::Collection.public_method(:new)
    end

    private

      def publish_doi(doi:)
        metadata_adapter = metadata_source
          .call(resource: collection, public_identifier: collection.uuid)

        client = client_source.call

        DoiService.publish_doi(doi: doi, metadata_adapter: metadata_adapter, client: client)
      end
  end
end
