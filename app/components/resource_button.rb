# frozen_string_literal: true

class ResourceButton < ApplicationComponent
  attr_reader :resource, :policy

  def initialize(resource:, policy: nil)
    @resource = resource
    @policy = policy
  end

  def method; end

  private

    def has_draft?
      return false if collection?

      resource.work.draft_version.present?
    end

    def collection?
      resource.is_a?(CollectionDecorator)
    end

    def type
      collection? ? 'Collection' : 'Work'
    end
end
