# frozen_string_literal: true

module DataCite
  class Metadata
    class Error < StandardError; end
    class ValidationError < Error; end

    attr_reader :work_version,
                :public_identifier

    attr_writer :public_url_source

    RESOURCE_TYPES = {
      Work::Types::DATASET => 'Dataset'
    }.freeze

    def initialize(work_version:, public_identifier:)
      @work_version = work_version
      @work = work_version.work
      @public_identifier = public_identifier
    end

    def attributes
      {
        titles: [{ title: work_version.title }],
        creators: creators,
        publicationYear: publication_year,
        types: {
          resourceTypeGeneral: resource_type
        },
        url: generate_url
      }
    end

    def validate!
      raise ValidationError.new("title can't be blank") if attributes[:titles].map { |t| t[:title] }.all?(&:blank?)

      raise ValidationError.new("publicationYear can't be blank") if attributes[:publicationYear].blank?

      raise ValidationError.new("Unknown mapping for work type: #{work.work_type.inspect}") if attributes.dig(
        :types, :resourceTypeGeneral
      ).blank?
    end

    def valid?
      validate! && true
    rescue Error
      false
    end

    def public_url_source
      @public_url_source ||= ->(id) {
        Rails.application.routes.url_helpers.resource_url(id)
      }
    end

    private

      attr_reader :work

      def creators
        work_version
          .creator_aliases
          .map { |ca| creator_attributes(ca) }
      end

      def creator_attributes(creator_alias)
        attrs = { name: creator_alias.alias }

        if orcid = creator_alias.actor.orcid.presence
          attrs[:nameIdentifiers] = [
            {
              nameIdentifier: orcid,
              nameIdentifierScheme: 'ORCID',
              schemeUri: 'http://orcid.org/'
            }
          ]
        end

        attrs
      end

      def publication_year
        date = parsed_publication_date || work_version.created_at
        date&.year
      end

      def parsed_publication_date
        Time.zone.parse(work_version.published_date.first)
      rescue ArgumentError, TypeError
        nil
      end

      def resource_type
        RESOURCE_TYPES[work.work_type]
      end

      def generate_url
        public_url_source.call(public_identifier)
      end
  end
end
