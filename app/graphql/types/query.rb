# frozen_string_literal: true

module Types
  class Query < GraphQL::Schema::Object
    description 'The query root of this schema'

    field :work, Work, null: true do
      description 'Find a work using its resource id'
      argument :id, Uuid, required: true
    end

    field :file, File, null: true do
      description 'Find a file using its legacy identifier from Scholarsphere 3 (available to administrators ONLY)'
      argument :pid, String, required: true
    end

    def work(id:)
      resource = FindResource.call(id)

      if resource.is_a?(WorkVersion)
        resource
      elsif resource.is_a?(::Work)
        resource.latest_version
      end
    end

    def file(pid:)
      return unless user.admin?

      LegacyIdentifier.find_by(old_id: pid).try(:resource)
    end

    private

      def user
        @user ||= context.fetch(:user, User.guest)
      end
  end
end
