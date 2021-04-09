# frozen_string_literal: true

module Types
  class Query < GraphQL::Schema::Object
    description 'The query root of this schema'

    field :work, Work, null: true do
      description 'Find a work using its resource id'
      argument :id, Uuid, required: true
    end

    def work(id:)
      resource = FindResource.call(id)

      if resource.is_a?(WorkVersion)
        resource
      elsif resource.is_a?(::Work)
        resource.latest_version
      end
    end
  end
end
