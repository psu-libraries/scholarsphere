# frozen_string_literal: true

module Orcid
  module Public
    class Email
      attr_reader :id

      def initialize(id:, data: nil)
        @id = id
        @data = data
      end

      def addresses
        @addresses ||= data.dig('email')
          .map { |record| Address.new(record) }
          .sort { |a, b| b.last_modified <=> a.last_modified }
      end

      def primary
        addresses.select(&:primary?).first&.to_s
      end

      def default
        primary || addresses.first&.to_s
      end

      class Address
        def initialize(entry)
          @entry = entry
        end

        def to_s
          @entry.dig('email')
        end

        # @return [String]
        # @note Options are 'LIMITED', 'REGISTERED_ONLY', 'PUBLIC', and 'PRIVATE', but since this is the public API,
        # 'PUBLIC' emails are only returned.
        def visibility
          @entry.dig('visibility')
        end

        # @return [Boolean]
        def verified?
          @entry.dig('verified')
        end

        # @return [Boolean]
        def primary?
          @entry.dig('primary')
        end

        # @return [Integer]
        def last_modified
          @entry.dig('last-modified-date', 'value')
        end
      end

      private

        def data
          @data ||= Public.get(action: 'email', id: id)
        end
    end
  end
end
