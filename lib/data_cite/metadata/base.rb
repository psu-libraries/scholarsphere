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
          descriptions: [
            {
              descriptionType: 'Abstract',
              description: resource.description
            }
          ],
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

        raise ValidationError.new("description can't be blank") if attributes[:descriptions].map { |d| d[:description] }.all?(&:blank?)
      end

      def public_url_source
        @public_url_source ||= ->(id) {
          Rails.application.routes.url_helpers.resource_url(id)
        }
      end

      private

        def creators
          resource
            .creators
            .map { |creator| creator_attributes(creator) }
        end

        def creator_attributes(creator)
          attrs = { name: creator.display_name }

          if orcid = creator.orcid.presence
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
