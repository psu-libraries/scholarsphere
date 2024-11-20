# frozen_string_literal: true

class DefaultSchema < BaseSchema
  def document
    attributes_for_indexing.map do |attribute|
      [field_name(attribute).to_sym, field_values(attribute)]
    end.to_h
  end

  private

    def attributes_for_indexing
      attribute_types.keys - ['id', 'metadata']
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

    def field_values(attribute)
      case attribute_types[attribute].type
      when :string then Array.wrap(resource[attribute]).compact
      when :datetime then resource[attribute]&.utc
      else
        resource[attribute]
      end
    end

    def attribute_types
      @attribute_types ||= (resource.class.try(:attribute_types) || {})
    end
end
