# frozen_string_literal: true

class FormTabsComponent < ApplicationComponent
  def initialize(resource:, current_controller:)
    @resource = resource
    @current_controller = current_controller
    @links_enabled = resource.persisted?
  end

  private

    attr_reader :resource,
                :current_controller,
                :links_enabled

    def tabs
      # Add clases to base tabs based on state
      base_tabs.each do |tab|
        tab.active = tab.controller == current_controller
        tab.classes = %w(nav-item nav-link)
        tab.classes << 'active' if tab.active
        tab.classes << 'disabled' unless links_enabled
      end
    end

    def base_tabs
      send("#{resource.model_name.param_key}_tabs")
    end

    def work_version_tabs
      [
        OpenStruct.new(
          label: I18n.t('dashboard.form.tabs.work_version_details'),
          url: links_enabled && dashboard_form_work_version_details_path(resource),
          controller: 'work_version_details',
          active: false,
          classes: []
        ),
        OpenStruct.new(
          label: I18n.t('dashboard.form.tabs.contributors'),
          url: links_enabled && dashboard_form_contributors_path('work_version', resource),
          controller: 'contributors',
          active: false,
          classes: []
        ),
        OpenStruct.new(
          label: I18n.t('dashboard.form.tabs.files'),
          url: links_enabled && dashboard_form_files_path(resource),
          controller: 'files',
          active: false,
          classes: []
        ),
        OpenStruct.new(
          label: I18n.t('dashboard.form.tabs.publish'),
          url: links_enabled && dashboard_form_publish_path(resource),
          controller: 'publish',
          active: false,
          classes: []
        )
      ]
    end

    def collection_tabs
      [
        OpenStruct.new(
          label: I18n.t('dashboard.form.tabs.collection_details'),
          url: links_enabled && dashboard_form_collection_details_path(resource),
          controller: 'collection_details',
          active: false,
          classes: []
        ),
        OpenStruct.new(
          label: I18n.t('dashboard.form.tabs.contributors'),
          url: links_enabled && dashboard_form_contributors_path('collection', resource),
          controller: 'contributors',
          active: false,
          classes: []
        ),
        OpenStruct.new(
          label: I18n.t('dashboard.form.tabs.members'),
          url: links_enabled && dashboard_form_members_path(resource),
          controller: 'members',
          active: false,
          classes: []
        )
      ]
    end
end
