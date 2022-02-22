# frozen_string_literal: true

class CollectionSchema < BaseSchema
  def document
    return {} unless resource.respond_to?(:draft?)

    {
      is_empty_bi: resource.draft?
    }
  end
end
