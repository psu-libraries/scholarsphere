# frozen_string_literal: true

module Types
  class Work < Types::BaseObject
    field :based_near, [String], null: true
    field :contributor, [String], null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :deposit_agreed_at, GraphQL::Types::ISO8601DateTime, null: true
    field :deposit_agreement_version, String, null: true
    field :deposited_at, GraphQL::Types::ISO8601DateTime, null: true
    field :description, String, null: true
    field :doi, String, null: true
    field :embargoed_until, GraphQL::Types::ISO8601DateTime, null: true
    field :id, Uuid, null: false
    field :identifier, [String], null: true
    field :keyword, [String], null: true
    field :language, [String], null: true
    field :published_date, String, null: true
    field :publisher, [String], null: true
    field :related_url, [String], null: true
    field :resource_type, [String], null: true
    field :rights, String, null: true
    field :source, [String], null: true
    field :status, String, null: false, method: :aasm_state
    field :subject, [String], null: true
    field :subtitle, String, null: true
    field :title, String, null: true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :version_name, String, null: true
    field :version_number, Int, null: false
    field :visibility, String, null: true
    field :work_type, String, null: true

    field :creators,
          [Types::Creator],
          null: true,
          description: 'Ordered listing of creators associated with this work'

    field :depositor,
          Types::Depositor,
          null: false,
          description: 'Penn State user who as deposited this work'

    field :files,
          [Types::File],
          null: false

    field :proxy_depositor,
          Types::Depositor,
          null: true,
          description: 'Penn State user who has depositor the work on behalf of the depositor'

    def files
      return [] unless Pundit.policy(user, object).download?

      object.file_resources
    end

    private

      def user
        @user ||= context.fetch(:user, User.guest)
      end
  end
end
