# frozen_string_literal: true

class ResourceSettingsButton < ResourceButton
  def path
    if collection?
      edit_dashboard_collection_path(resource)
    else
      edit_dashboard_work_path(resource)
    end
  end

  def label
    I18n.t('resources.settings_button.text', type: type)
  end

  def tooltip
    I18n.t('resources.settings_button.tooltip')
  end

  def icon
    'settings'
  end
end
