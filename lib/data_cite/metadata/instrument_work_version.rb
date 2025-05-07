# frozen_string_literal: true

module DataCite
  module Metadata
    class InstrumentWorkVersion < Base
      def attributes
        attributes = super
        if available_date
          attributes[:dates] = [
            {
              dateType: 'Other',
              dateInformation: 'Commissioned',
              date: available_date
            }
          ]
        end
        attributes[:creators] = [
          {
            name: resource.manufacturer,
            nameType: 'Organizational'
          }
        ]
        attributes[:contributors] = [
          {
            name: resource.owner,
            contributorType: 'HostingInstitution'
          }
        ]
        attributes
      end

      def validate!
        super

        unless attributes[:creators].find { |c| c[:nameType] == 'Organizational' && c[:name].present? }
          raise ValidationError.new('must include an organizational creator (manufacturer)')
        end

        unless attributes[:contributors].find { |c| c[:contributorType] == 'HostingInstitution' && c[:name].present? }
          raise ValidationError.new('must include a HostingInstitution contributor (owner)')
        end
      end

      private

        def resource_type
          'Instrument'
        end

        def available_date
          parsed_available_date&.edtf
        end

        def parsed_available_date
          return nil unless EdtfDate.valid?(resource.available_date)

          Date.edtf(resource.available_date)
        rescue ArgumentError, TypeError
          nil
        end
    end
  end
end
