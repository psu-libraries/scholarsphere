# frozen_string_literal: true

module DataCite
  module Metadata
    class Error < StandardError; end
    class ValidationError < Error; end

    class Base
      attr_reader :resource,
                  :public_identifier

      attr_writer :public_url_source

      def initialize(resource:, public_identifier:)
        @resource = resource
        @public_identifier = public_identifier
      end

      def attributes
        {
          titles: [{ title: resource.title }],
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

        def creators
          creator_aliases
            .map { |ca| creator_attributes(ca) }
        end

        def creator_aliases
          resource.creator_aliases
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
          publication_date&.year
        end

        def publication_date
          parsed_publication_date || resource.created_at
        end

        def parsed_publication_date
          return nil unless EdtfDate.valid?(resource.published_date)

          Date.edtf(resource.published_date)
        rescue ArgumentError, TypeError
          nil
        end

        # Implement this in your subclass. It should return back a string of the
        # resource type as described by DataCite's API
        def resource_type
          raise NotImplementedError
        end

        def generate_url
          public_url_source.call(public_identifier)
        end
    end
  end
end
