# frozen_string_literal: true

module FeatureHelpers
  module WorkForm
    extend Capybara::DSL

    def self.fill_in_minimal_work_details_for_draft(work_version_metadata)
      fill_in 'work_version_title', with: work_version_metadata[:title]
      select Work::Types.display(Work::Types.default), from: 'work_version_work_attributes_work_type'
    end

    def self.fill_in_work_details(work_version_metadata)
      fill_in_minimal_work_details_for_draft(work_version_metadata)

      fill_in 'work_version_description', with: work_version_metadata[:description]
      fill_in 'work_version_published_date', with: work_version_metadata[:published_date]
      fill_in 'work_version_keyword', with: work_version_metadata[:keyword]

      fill_in 'work_version_subtitle', with: work_version_metadata[:subtitle]
      fill_in 'work_version_version_name', with: work_version_metadata[:version_name]
      fill_in 'work_version_publisher', with: work_version_metadata[:publisher]
      fill_in 'work_version_subject', with: work_version_metadata[:subject]
      fill_in 'work_version_language', with: work_version_metadata[:language]
      fill_in 'work_version_related_url', with: work_version_metadata[:related_url]
      fill_in 'work_version_identifier', with: work_version_metadata[:identifier]
      fill_in 'work_version_based_near', with: work_version_metadata[:based_near]
      fill_in 'work_version_source', with: work_version_metadata[:source]
    end

    def self.fill_in_contributors(metadata)
      # NOOP
      # at the moment this does nothing, but once we finalize the contributors
      # form with javascript, fill in this method
    end

    def self.upload_file(file_path)
      # Wait for Uppy to load
      while page.has_no_selector?('.uppy-Dashboard-AddFiles')
        sleep 0.1
      end

      # @note For some reason there are two 'files[]' hidden inputs, but it's only happens in the test environment.
      page
        .all('.uppy-Dashboard-input', visible: false)
        .first
        .attach_file(file_path)

      # Wait for file to finish uploading
      while page.has_no_selector?('.uppy-DashboardContent-title', text: 'Upload complete')
        sleep 0.1
      end
    end

    def self.fill_in_publishing_details(_metadata)
      choose "work_version_work_attributes_visibility_#{Permissions::Visibility::OPEN}"
      check 'work_version_depositor_agreement'
    end

    def self.save_as_draft_and_exit
      fix_sticky_footer
      click_on I18n.t('dashboard.work_form.actions.save_and_exit')
    end

    def self.save_and_continue
      fix_sticky_footer
      click_on I18n.t('dashboard.work_form.actions.save_and_continue')
    end

    def self.publish
      fix_sticky_footer
      click_on I18n.t('dashboard.work_form.actions.publish')
    end

    def self.fix_sticky_footer
      Capybara.current_session.current_window.resize_to(1000, 1000)
    rescue Capybara::NotSupportedByDriverError
    end

    # @note In theory, #assert_selector should be AJAX-aware
    def self.search_creators(query)
      fill_in('search-creators', with: query)

      page.assert_selector('.aa-dataset-1')
    end
  end
end
