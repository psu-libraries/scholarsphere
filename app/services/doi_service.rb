# frozen_string_literal: true

require 'data_cite'

class DoiService
  class Error < StandardError; end

  def self.call(resource, client_source: nil, metadata_source: nil)
    instance = new(resource)
    instance.client_source = client_source
    instance.metadata_source = metadata_source
    instance.call
  end

  attr_reader :resource

  attr_writer :client_source,
              :metadata_source

  def initialize(resource)
    @resource = resource

    raise Error.new("Cannot mint a doi for an invalid resource: #{resource.inspect}") unless resource.valid?

    if resource.is_a? WorkVersion
      @work_version = resource
    elsif resource.is_a? Work
      @work_version = resource.latest_version
    else
      raise ArgumentError, 'DoiService expects resource to be a Work or WorkVersion'
    end
  end

  def call
    if resource.doi.blank? && work_version.draft?
      register_and_save_new_doi
    elsif resource.doi.present? && work_version.draft?
      # No-op
    else
      existing_doi = resource.doi.presence
      should_save_new_doi = existing_doi.blank?

      publish_doi(
        doi: existing_doi, # will register a new doi if nil
        update_resource: should_save_new_doi
      )
    end
  end

  def client_source
    @client_source ||= DataCite::Client.public_method(:new)
  end

  def metadata_source
    @metadata_source ||= DataCite::Metadata.public_method(:new)
  end

  private

    attr_reader :work_version

    def register_and_save_new_doi
      new_doi, _response_metadata = client_source.call.register
      save_doi(new_doi)
    end

    def publish_doi(doi:, update_resource:)
      metadata = metadata_source
        .call(work_version: work_version, public_identifier: resource.uuid)
        .tap(&:validate!)
        .attributes

      response_doi, _response_metadata = client_source.call.publish(
        doi: doi,
        metadata: metadata
      )

      save_doi(response_doi) if update_resource
    end

    def save_doi(doi)
      resource.update!(doi: doi)
    end
end
