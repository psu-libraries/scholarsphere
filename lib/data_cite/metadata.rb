# frozen_string_literal: true

module DataCite
  class Metadata
    class Error < StandardError; end
    class ValidationError < Error; end

    attr_reader :work_version

    RESOURCE_TYPES = {
      Work::Types::DATASET => 'Dataset'
    }.freeze

    def initialize(work_version:)
      @work_version = work_version
      @work = work_version.work
    end

    def attributes
      {
        titles: [{ title: work_version.title }],
        creators: [creator],
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

    private

      attr_reader :work

      def creator
        {
          givenName: work.depositor.given_name,
          familyName: work.depositor.surname
        }
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
        'http://example.test'
      end
  end
end
