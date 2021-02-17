# frozen_string_literal: true

class CreatorSchema < BaseSchema
  def document
    return {} unless resource.respond_to?(:creators)

    {
      creators_sim: resource.creators.map(&:alias),
      creators_tesim: resource.creators.map(&:alias)
    }
  end
end
