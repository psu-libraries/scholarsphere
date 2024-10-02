# frozen_string_literal: true

module DataCite
  module Metadata
    class WorkVersion < Base
      RESOURCE_TYPES = {
        'article' => 'Text',
        'audio' => 'Sound',
        'book' => 'Text',
        'capstone_project' => 'Text',
        'conference_proceeding' => 'Text',
        'dataset' => 'Dataset',
        'dissertation' => 'Text',
        'image' => 'Image',
        'instrument' => 'Instrument',
        'journal' => 'Text',
        'map_or_cartographic_material' => 'Image',
        'masters_culminating_experience' => 'Text',
        'masters_thesis' => 'Text',
        'other' => 'Other',
        'part_of_book' => 'Text',
        'poster' => 'Audiovisual',
        'presentation' => 'Text',
        'project' => 'Other',
        'report' => 'Text',
        'research_paper' => 'Text',
        'software_or_program_code' => 'Software',
        'thesis' => 'Text',
        'unspecified' => 'Other',
        'video' => 'Audiovisual'
      }.freeze

      def validate!
        super

        raise ValidationError.new("Unknown mapping for work type: #{work_type.inspect}") if attributes.dig(
          :types, :resourceTypeGeneral
        ).blank?
      end

      private

        def work_type
          resource.work.work_type
        end

        def resource_type
          RESOURCE_TYPES[work_type]
        end
    end
  end
end
