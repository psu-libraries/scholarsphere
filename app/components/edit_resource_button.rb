# frozen_string_literal: true

class EditResourceButton < ApplicationComponent
  attr_reader :resource, :policy

  def initialize(resource:, policy:)
    @resource = resource
    @policy = policy
  end

  def path
    if collection?
      dashboard_form_collection_details_path(resource.id)
    elsif has_draft?
      # update the existing draft version
      dashboard_form_work_version_details_path(resource.work.draft_version.id)
    elsif policy.new?
      # create a new draft work version
      dashboard_work_work_versions_path(resource.work)
    end
  end

  def label
    I18n.t('resources.edit_button.text', type: type)
  end

  def method
    return if collection? || has_draft?

    'post'
  end

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
