# frozen_string_literal: true

# This component wraps MintingStatusDoiComponent with a button that allows a
# user to mint a doi if a) the resource doesn't already have one b) the user has
# permission to do so.

class MintableDoiComponent < ApplicationComponent
  attr_writer :minting_policy_source

  attr_reader :resource

  def initialize(resource:)
    @resource = resource
  end

  def render?
    minting_status_doi_component.render? || user_can_mint_doi?
  end

  def user_can_mint_doi?
    return false if resource.blank?

    @user_can_mint_doi ||= minting_policy_source.call(resource)
  end

  def minting_status_doi_component
    MintingStatusDoiComponent.new(resource: resource)
  end

  # Components can call view helpers through the `helpers` method, as is done in
  # the body of the lambda below. However, the one below to retrieve the pundit
  # policy relies on current_user, which also relies on having Warden up and
  # running. This is no problem in the actual environment, but in unit tests
  # it's not available. We can use this class-level *_source pattern to stub
  # this out during tests.
  def minting_policy_source
    @minting_policy_source ||= ->(resource) { helpers.policy(resource).edit? }
  end
end
