# frozen_string_literal: true

class CollectionSchema < BaseSchema
  def document
    return {} unless resource.respond_to?(:empty?)

    {
      is_empty_bsi: resource.empty?
    }
  end
end
