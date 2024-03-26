# frozen_string_literal: true

require 'rails_helper'
require 'support/vcr'

RSpec.describe 'Autocompleting WorkVersion metadata with data from RMD', with_user: :user, vcr: true do
  let(:user) { create(:user) }
  let(:metadata) { attributes_for(:work_version, :with_complete_metadata) }

  describe 'Submitting the Autcomplete For Open Access Works form' do
    context 'when work type is not a scholarly work' do
      it 'does not render Autocomplete For Open Access Works form' do
        visit dashboard_form_work_versions_path

        FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_data_and_code_draft(metadata)
        FeatureHelpers::DashboardForm.save_and_continue

        expect(page).not_to have_content 'Autocomplete for Open Access Works'
        expect(page).not_to have_css '#autocomplete_work_form_doi'
      end
    end

    context 'when work type is a scholarly work' do
      context 'when valid DOI is submitted' do
        context 'when metadata is found' do
          it 'renders the Work Details page with completed forms where metadata was found' do
            visit dashboard_form_work_versions_path

            FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_scholarly_works_draft(metadata)
            FeatureHelpers::DashboardForm.save_and_continue

            fill_in 'autocomplete_work_form_doi', with: 'https://doi.org/10.1038/abcdefg1234567'
            click_on 'Submit'

            expect(page).to have_content 'We were able to find your work and autocomplete some metadata for you'
          end
        end

        context 'when metadata is not found' do
          it 'renders the Work Details page with a flash indicating nothing was found' do
            visit dashboard_form_work_versions_path

            FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_scholarly_works_draft(metadata)
            FeatureHelpers::DashboardForm.save_and_continue

            fill_in 'autocomplete_work_form_doi', with: 'https://doi.org/10.1038/abcdefg1234567'
            click_on 'Submit'

            expect(page).to have_content 'We were not able to find and autocomplete the metadata for your work'
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

          expect(page).to have_content 'Autocomplete failed: not a valid DOI'
        end
      end
    end
  end
end
