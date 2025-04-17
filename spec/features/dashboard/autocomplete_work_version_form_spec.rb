# frozen_string_literal: true

require 'rails_helper'
require 'support/vcr'

RSpec.describe 'Autocompleting WorkVersion metadata with data from RMD', :vcr, with_user: :user do
  let(:user) { create(:user) }
  let(:metadata) { attributes_for(:work_version, :with_complete_metadata) }

  describe 'Submitting the Autcomplete For Open Access Works form' do
    context 'when work type is not a scholarly work' do
      it 'does not render Autocomplete For Open Access Works form' do
        visit dashboard_form_work_versions_path

        FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_data_and_code_draft(metadata)
        FeatureHelpers::DashboardForm.save_and_continue

        expect(page).to have_no_content 'Autocomplete for Open Access Works'
        expect(page).to have_no_css '#autocomplete_work_form_doi'
      end
    end

    context 'when work type is a scholarly work' do
      context 'when valid DOI is submitted' do
        context 'when metadata is found' do
          before do
            visit dashboard_form_work_versions_path

            FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_scholarly_works_draft(metadata)
            FeatureHelpers::DashboardForm.save_and_continue

            fill_in 'autocomplete_work_form_doi', with: 'https://doi.org/10.1038/abcdefg1234567'
            click_on 'Submit'
          end

          context 'when the user is not an admin' do
            it 'renders the Work Details page with completed forms where metadata was found' do
              expect(WorkVersion.last.imported_metadata_from_rmd).to eq true
              expect(page).to have_content 'We were able to find your work and autocomplete some metadata for you'
              expect(page).to have_no_css '#autocomplete_work_form_doi'
              expect(find_by_id('work_version_title').value).to eq 'A Scholarly Research Article'
              expect(find_by_id('work_version_description').text).to eq 'A summary of the research'
              expect(find_by_id('work_version_published_date').value).to eq '2010-12-05'
              expect(find_by_id('work_version_subtitle').value).to eq 'A Comparative Analysis'
              expect(find_by_id('work_version_publisher').value).to eq 'An Academic Journal'
              expect(find_by_id('work_version_identifier').value).to eq 'https://doi.org/10.1038/abcdefg1234567'
              expect(find_by_id('work_version_identifier').readonly?).to eq true
              expect(find_by_id('work_version_identifier').find(:xpath, './../..').native.attribute_nodes.first.value).to eq 'mb-1'
              keywords = find_all('#work_version_keyword')
              expect(keywords[0].value).to eq 'A Topic'
              expect(keywords[1].value).to eq 'Another Topic'
              related_urls = find_all('#work_version_related_url')
              expect(related_urls[0].value).to eq 'https://example.org/articles/article-123.pdf'

              # Check that the contributors were imported
              click_on 'Contributors'

              expect(find_by_id('work_version_creators_attributes_0_display_name').value).to eq 'Anne Example Contributor'
              expect(find_by_id('work_version_creators_attributes_0_given_name').value).to eq 'Anne'
              expect(find_by_id('work_version_creators_attributes_0_surname').value).to eq 'Contributor'
              expect(find_by_id('work_version_creators_attributes_0_email').value).to eq nil
              expect(page).to have_content('Unidentified').once
              expect(find_by_id('work_version_creators_attributes_1_display_name').value).to eq 'Joe Fakeman Person'
              expect(find_by_id('work_version_creators_attributes_1_given_name').value).to eq 'Joe'
              expect(find_by_id('work_version_creators_attributes_1_surname').value).to eq 'Person'
              expect(find_by_id('work_version_creators_attributes_1_email').value).to eq 'def1234@psu.edu'
              expect(page).to have_content('Access Account: def1234').once

              click_on 'Work Type'

              # Check that work type is disabled on work type form
              expect(find_by_id('work_version_work_attributes_work_type').disabled?).to eq true

              click_on 'Review & Publish'

              # Check that work type and identifier are disabled on publish form
              expect(find_by_id('work_version_work_attributes_work_type').disabled?).to eq true
              expect(find_by_id('work_version_identifier').readonly?).to eq true
            end
          end

          context 'when the user is an admin' do
            let(:user) { create(:user, :admin) }

            it 'allows admin to edit publisher doi' do
              expect(find_by_id('work_version_identifier').readonly?).to eq false
            end
          end
        end

        context 'when metadata is not found' do
          it 'renders the Work Details page with a flash indicating nothing was found' do
            visit dashboard_form_work_versions_path

            FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_scholarly_works_draft(metadata)
            FeatureHelpers::DashboardForm.save_and_continue

            fill_in 'autocomplete_work_form_doi', with: 'https://doi.org/10.1038/abcdefg1234567'
            click_on 'Submit'

            expect(WorkVersion.last.imported_metadata_from_rmd).to eq false
            expect(page).to have_content 'We were not able to find and autocomplete the metadata for your work'
            expect(page).to have_no_css '#autocomplete_work_form_doi'
            expect(page).to have_no_css '#work_version_title'
          end
        end
      end

      context 'when invalid DOI is submitted' do
        it 'renders the Work Details page with a flash indicating the DOI is invalid' do
          visit dashboard_form_work_versions_path

          FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_scholarly_works_draft(metadata)
          FeatureHelpers::DashboardForm.save_and_continue

          fill_in 'autocomplete_work_form_doi', with: 'abcdefghi123456'
          click_on 'Submit'

          expect(WorkVersion.last.imported_metadata_from_rmd).to eq nil
          expect(page).to have_content 'Autocomplete failed: not a valid DOI'
          expect(page).to have_css '#autocomplete_work_form_doi'
        end
      end
    end
  end
end
