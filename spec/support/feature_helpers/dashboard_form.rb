# frozen_string_literal: true

module FeatureHelpers
  module DashboardForm
    extend Capybara::DSL

    def self.fill_in_minimal_work_details_for_draft(work_version_metadata)
      fill_in 'work_version_title', with: work_version_metadata[:title]
      select Work::Types.display('other'), from: 'work_version_work_attributes_work_type'
    end

    def self.fill_in_minimal_work_details_for_scholarly_works_draft(work_version_metadata)
      fill_in 'work_version_title', with: work_version_metadata[:title]
      select Work::Types.display('article'), from: 'work_version_work_attributes_work_type'
    end

    def self.fill_in_work_details(work_version_metadata)
      fill_in_scholarly_works_work_details(work_version_metadata)
      fill_in 'work_version_based_near', with: work_version_metadata[:based_near]
      fill_in 'work_version_source', with: work_version_metadata[:source]
    end

    def self.fill_in_scholarly_works_work_details(work_version_metadata)
      fill_in 'work_version_description', with: work_version_metadata[:description]
      fill_in 'work_version_publisher_statement', with: work_version_metadata[:publisher_statement]
      fill_in 'work_version_published_date', with: work_version_metadata[:published_date]
      fill_in 'work_version_keyword', with: work_version_metadata[:keyword]

      fill_in 'work_version_subtitle', with: work_version_metadata[:subtitle]
      fill_in 'work_version_publisher', with: work_version_metadata[:publisher]
      fill_in 'work_version_subject', with: work_version_metadata[:subject]
      fill_in 'work_version_language', with: work_version_metadata[:language]
      fill_in 'work_version_related_url', with: work_version_metadata[:related_url]
      fill_in 'work_version_identifier', with: work_version_metadata[:identifier]
    end

    def self.fill_in_minimal_collection_details(collection_metadata)
      fill_in 'collection_title', with: collection_metadata[:title]
      fill_in 'collection_description', with: collection_metadata[:description]
    end

    def self.fill_in_collection_details(collection_metadata)
      fill_in_minimal_collection_details(collection_metadata)

      fill_in 'collection_published_date', with: collection_metadata[:published_date]
      fill_in 'collection_keyword', with: collection_metadata[:keyword]
      fill_in 'collection_subtitle', with: collection_metadata[:subtitle]
      fill_in 'collection_publisher', with: collection_metadata[:publisher]
      fill_in 'collection_identifier', with: collection_metadata[:identifier]
      fill_in 'collection_related_url', with: collection_metadata[:related_url]
      fill_in 'collection_subject', with: collection_metadata[:subject]
      fill_in 'collection_language', with: collection_metadata[:language]
      fill_in 'collection_based_near', with: collection_metadata[:based_near]
      fill_in 'collection_source', with: collection_metadata[:source]
    end

    def self.select_work(title)
      page
        .find_all('.select2-results__option')
        .select { |option| option.text == title }
        .first
        .click
      while page.has_no_selector?('h3', text: /#{title}/i)
        sleep 0.1
      end
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

    def self.fill_in_publishing_details(metadata, visibility: Permissions::Visibility::OPEN)
      choose "work_version_work_attributes_visibility_#{visibility}"
      check 'work_version_depositor_agreement'
      select WorkVersion::Licenses.label(metadata[:rights]), from: 'work_version_rights'
    end

    def self.fill_in_publishing_details_published(metadata)
      check 'work_version_depositor_agreement'
      select WorkVersion::Licenses.label(metadata[:rights]), from: 'work_version_rights'
    end

    def self.save_as_draft_and_exit
      fix_sticky_footer
      click_on I18n.t!('dashboard.form.actions.save_and_exit.work_version')
    end

    def self.save_and_exit
      fix_sticky_footer
      click_on I18n.t!('dashboard.form.actions.save_and_exit.collection')
    end

    def self.save_and_continue
      fix_sticky_footer
      click_on I18n.t!('dashboard.form.actions.save_and_continue')
    end

    def self.publish
      fix_sticky_footer
      click_on I18n.t!('dashboard.form.actions.publish')
    end

    def self.finish
      fix_sticky_footer
      click_on I18n.t!('dashboard.form.actions.finish')
    end

    def self.delete
      fix_sticky_footer
      click_on I18n.t!('dashboard.form.actions.destroy.button')
    end

    def self.cancel
      fix_sticky_footer
      click_on I18n.t!('dashboard.form.actions.cancel')
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
