# frozen_string_literal: true

module Types
  class Depositor < Types::BaseObject
    field :display_name, String, null: true
    field :given_name, String, null: true
    field :family_name, String, null: false, method: :surname
    field :psu_id, String, null: true
    field :orcid, String, null: true
    field :email, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
