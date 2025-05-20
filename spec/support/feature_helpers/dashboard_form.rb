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

    def self.fill_in_minimal_work_details_for_data_and_code_draft(work_version_metadata)
      fill_in 'work_version_title', with: work_version_metadata[:title]
      select Work::Types.display('dataset'), from: 'work_version_work_attributes_work_type'
    end

    def self.fill_in_minimal_work_details_for_instrument_draft(work_version_metadata)
      fill_in 'work_version_title', with: work_version_metadata[:title]
      select Work::Types.display('instrument'), from: 'work_version_work_attributes_work_type'
    end

    def self.fill_in_minimal_work_details_for_grad_culminating_experiences_draft(work_version_metadata)
      fill_in 'work_version_title', with: work_version_metadata[:title]
      select Work::Types.display('masters_culminating_experience'), from: 'work_version_work_attributes_work_type'
    end

    def self.fill_in_common_work_details(work_version_metadata)
      fill_in 'work_version_description', with: work_version_metadata[:description]
      fill_in 'work_version_published_date', with: work_version_metadata[:published_date]
      fill_in 'work_version_keyword', with: work_version_metadata[:keyword]

      fill_in 'work_version_subtitle', with: work_version_metadata[:subtitle]
      fill_in 'work_version_publisher', with: work_version_metadata[:publisher]
      fill_in 'work_version_subject', with: work_version_metadata[:subject]
      fill_in 'work_version_language', with: work_version_metadata[:language]
      fill_in 'work_version_related_url', with: work_version_metadata[:related_url]
    end

    def self.fill_in_work_details(work_version_metadata)
      fill_in_common_work_details(work_version_metadata)
      fill_in 'work_version_identifier', with: work_version_metadata[:identifier]
      fill_in 'work_version_publisher_statement', with: work_version_metadata[:publisher_statement]
      fill_in 'work_version_based_near', with: work_version_metadata[:based_near]
      fill_in 'work_version_source', with: work_version_metadata[:source]
    end

    def self.fill_in_data_and_code_work_details(work_version_metadata)
      fill_in_common_work_details(work_version_metadata)
      fill_in 'work_version_based_near', with: work_version_metadata[:based_near]
      fill_in 'work_version_source', with: work_version_metadata[:source]
    end

    def self.fill_in_instrument_work_details(work_version_metadata)
      fill_in 'work_version_description', with: work_version_metadata[:description]
      fill_in 'work_version_published_date', with: work_version_metadata[:published_date]
      fill_in 'work_version_model', with: work_version_metadata[:model]
    end

    def self.fill_in_instrument_contributors(work_version_metadata)
      fill_in 'work_version_owner', with: work_version_metadata[:owner]
      fill_in 'work_version_manufacturer', with: work_version_metadata[:manufacturer]
    end

    def self.fill_in_scholarly_works_work_details(work_version_metadata)
      fill_in_common_work_details(work_version_metadata)
      fill_in 'work_version_identifier', with: work_version_metadata[:identifier]
      fill_in 'work_version_publisher_statement', with: work_version_metadata[:publisher_statement]
    end

    def self.fill_in_grad_culminating_experiences_work_details(work_version_metadata)
      fill_in 'work_version_description', with: work_version_metadata[:description]
      fill_in 'work_version_published_date', with: work_version_metadata[:published_date]
      select work_version_metadata[:sub_work_type], from: 'work_version_sub_work_type'
      select work_version_metadata[:program], from: 'work_version_program'
      select work_version_metadata[:degree], from: 'work_version_degree'
      fill_in 'work_version_keyword', with: work_version_metadata[:keyword]
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

    def self.upload_image(file_path = Rails.root.join('spec', 'fixtures', 'image.png'))
      # Wait for Uppy to load
      while page.has_no_selector?('.uppy-Dashboard-AddFiles')
        sleep 0.1
      end

      # @note For some reason there are two 'files[]' hidden inputs, but it's only happens in the test environment.
      page
        .all('.uppy-Dashboard-input', visible: false)
        .first
        .attach_file(file_path)

      # Wait for alt text form
      while page.has_no_selector?('#uppy-Dashboard-FileCard-input-alt_text')
        sleep 0.1
      end

      fill_in 'uppy-Dashboard-FileCard-input-alt_text', with: 'Test alt text'

      click_on 'Save changes'

      # Wait for file to finish uploading
      while page.has_no_selector?('.uppy-DashboardContent-title', text: 'Upload complete')
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
      select WorkVersion::Licenses.label(metadata[:rights]), from: 'work_version_rights'
    end

    def self.fill_in_publishing_details_published(metadata)
      select WorkVersion::Licenses.label(metadata[:rights]), from: 'work_version_rights'
    end

    def self.save_as_draft_and_exit
      click_on I18n.t!('dashboard.form.actions.save_and_exit.work_version')
    end

    def self.save_and_exit
      click_on I18n.t!('dashboard.form.actions.save_and_exit.collection')
    end

    def self.save_and_continue
      click_on I18n.t!('dashboard.form.actions.save_and_continue.button')
    end

    def self.publish
      click_on I18n.t!('dashboard.form.actions.publish.button')
      check_agreement_boxes
      click_on I18n.t!('dashboard.form.actions.confirm.publish')
    end

    def self.request_curation
      click_on I18n.t!('dashboard.form.actions.request_curation.button')
      check_agreement_boxes
      click_on I18n.t!('dashboard.form.actions.confirm.request_curation')
    end

    def self.request_remediation
      click_on I18n.t!('dashboard.form.actions.request_remediation.button')
      check_agreement_boxes
      click_on I18n.t!('dashboard.form.actions.confirm.request_remediation')
    end

    def self.finish
      click_on I18n.t!('dashboard.form.actions.finish.button')
    end

    def self.delete
      click_on I18n.t!('dashboard.form.actions.destroy.button')
    end

    def self.cancel
      click_on I18n.t!('dashboard.form.actions.cancel.button')
    end

    def self.check_agreement_boxes
      check 'work_version_depositor_agreement'
      check 'work_version_psu_community_agreement'
      check 'work_version_accessibility_agreement'
      check 'work_version_sensitive_info_agreement'
    end

    # @note In theory, #assert_selector should be AJAX-aware
    def self.search_creators(query)
      fill_in('search-creators', with: query)

      page.assert_selector('.aa-dataset-1')
    end
  end
end
