# frozen_string_literal: true

class DefaultSchema
  attr_reader :resource_klass

  # @param [ActiveRecord::Base]
  def initialize(resource_klass)
    @resource_klass = resource_klass
  end

  def schema
    solr_fields.map do |solr_field|
      solr_field
    end.to_h
  end

  private

    def solr_fields
      (attribute_types.keys - ['id', 'metadata']).map do |attribute|
        [field_name(attribute), Array.wrap(attribute)]
      end
    end

    def field_name(attribute)
      case attribute_types[attribute].type
      when :integer then "#{attribute}_isi"
      when :datetime then "#{attribute}_dtsi"
      when :uuid then "#{attribute}_ssi"
      else
        "#{attribute}_tesim"
      end
    end

    def attribute_types
      @attribute_types ||= (resource_klass.try(:attribute_types) || {})
    end
end
