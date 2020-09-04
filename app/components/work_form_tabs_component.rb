# frozen_string_literal: true

class WorkFormTabsComponent < ApplicationComponent
  # @param [Work, SolrDocument]
  def initialize(work_version:, current_controller:)
    @work_version = work_version
    @current_controller = current_controller
    @links_enabled = work_version.persisted?
  end

  private

    attr_reader :work_version,
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
      [
        OpenStruct.new(
          label: I18n.t('dashboard.work_form.tabs.details'),
          url: links_enabled && dashboard_work_form_details_path(work_version),
          controller: 'details',
          active: false,
          classes: []
        ),
        OpenStruct.new(
          label: I18n.t('dashboard.work_form.tabs.contributors'),
          url: links_enabled && dashboard_work_form_contributors_path(work_version),
          controller: 'contributors',
          active: false,
          classes: []
        ),
        OpenStruct.new(
          label: I18n.t('dashboard.work_form.tabs.files'),
          url: links_enabled && dashboard_work_form_files_path(work_version),
          controller: 'files',
          active: false,
          classes: []
        ),
        OpenStruct.new(
          label: I18n.t('dashboard.work_form.tabs.publish'),
          url: links_enabled && dashboard_work_form_publish_path(work_version),
          controller: 'publish',
          active: false,
          classes: []
        )
      ]
    end
end
