# frozen_string_literal: true

class CreatorSchema < BaseSchema
  def document
    return {} unless resource.respond_to?(:creators)

    {
      creators_sim: resource.creators.map(&:default_alias),
      creator_aliases_tesim: resource.creator_aliases.map(&:alias)
    }
  end
end
