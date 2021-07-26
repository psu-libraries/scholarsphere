# frozen_string_literal: true

class ResourceEditButton < ResourceButton
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

  def tooltip
    I18n.t('resources.edit_button.tooltip')
  end

  def icon
    'edit'
  end

  def method
    return if collection? || has_draft?

    'post'
  end
end
