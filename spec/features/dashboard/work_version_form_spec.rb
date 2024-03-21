# frozen_string_literal: true

require 'rails_helper'
require 'support/vcr'

RSpec.describe 'Publishing a work', with_user: :user do
  let(:user) { create(:user) }
  let(:metadata) { attributes_for(:work_version, :with_complete_metadata) }

  before do
    allow(SolrIndexingJob).to receive(:perform_later)
  end

  describe 'The Work Details tab for a new work' do
    context 'when selecting a work type that uses the general deposit pathway' do
      context 'when saving as draft and exiting' do
        it 'creates a new work with all fields provided' do
          initial_work_count = Work.count

          visit dashboard_form_work_versions_path

          FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_draft(metadata)
          FeatureHelpers::DashboardForm.save_as_draft_and_exit

          expect(Work.count).to eq(initial_work_count + 1)

          new_work = Work.last
          expect(new_work.work_type).to eq 'other'
          expect(new_work.versions.length).to eq 1

          new_work_version = new_work.versions.last
          expect(page).to have_content(metadata[:title])
          expect(new_work_version.title).to eq metadata[:title]
          expect(new_work_version.version_number).to eq 1

          expect(page).to have_current_path(resource_path(new_work_version.uuid))
          expect(SolrIndexingJob).to have_received(:perform_later).at_least(:once)
        end
      end

      context 'when saving and_continuing' do
        it 'creates a new work with all fields provided' do
          initial_work_count = Work.count

          visit dashboard_form_work_versions_path

          FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_draft(metadata)
          FeatureHelpers::DashboardForm.save_and_continue
          FeatureHelpers::DashboardForm.fill_in_work_details(metadata)
          FeatureHelpers::DashboardForm.save_and_continue

          expect(Work.count).to eq(initial_work_count + 1)
          new_work = Work.last
          expect(new_work.work_type).to eq 'other'
          expect(new_work.versions.length).to eq 1

          new_work_version = new_work.versions.last
          expect(new_work_version.version_number).to eq 1
          expect(new_work_version.title).to eq metadata[:title]
          expect(new_work_version.description).to eq metadata[:description]
          expect(new_work_version.publisher_statement).to eq metadata[:publisher_statement]
          expect(new_work_version.published_date).to eq metadata[:published_date]
          expect(new_work_version.keyword).to eq [metadata[:keyword]]
          expect(new_work_version.subtitle).to eq metadata[:subtitle]
          expect(new_work_version.version_name).to eq metadata[:version_name]
          expect(new_work_version.publisher).to eq [metadata[:publisher]]
          expect(new_work_version.subject).to eq [metadata[:subject]]
          expect(new_work_version.language).to eq [metadata[:language]]
          expect(new_work_version.related_url).to eq [metadata[:related_url]]
          expect(new_work_version.identifier).to eq [metadata[:identifier]]
          expect(new_work_version.based_near).to eq [metadata[:based_near]]
          expect(new_work_version.source).to eq [metadata[:source]]

          expect(page).to have_current_path(dashboard_form_contributors_path('work_version', new_work_version))
          expect(SolrIndexingJob).to have_received(:perform_later).at_least(:twice)
        end

        context 'with invalid data' do
          it 'does not save the data and rerenders the form with errors' do
            visit dashboard_form_work_versions_path

            FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_draft(metadata)
            FeatureHelpers::DashboardForm.save_and_continue
            FeatureHelpers::DashboardForm.fill_in_work_details(metadata)
            fill_in 'work_version_description', with: ''
            FeatureHelpers::DashboardForm.save_and_continue

            new_work_version = Work.last.versions.last

            expect(page).to have_current_path(dashboard_form_work_version_details_path(new_work_version))
            expect(page).to have_content 'Description is required to publish the work'
            expect(SolrIndexingJob).to have_received(:perform_later).once

            expect(new_work_version.description).to be_nil
            expect(new_work_version.publisher_statement).to be_nil
            expect(new_work_version.published_date).to be_nil
            expect(new_work_version.keyword).to be_empty
            expect(new_work_version.subtitle).to be_nil
            expect(new_work_version.version_name).to be_nil
            expect(new_work_version.publisher).to be_empty
            expect(new_work_version.subject).to be_empty
            expect(new_work_version.language).to be_empty
            expect(new_work_version.related_url).to be_empty
            expect(new_work_version.identifier).to be_empty
            expect(new_work_version.based_near).to be_empty
            expect(new_work_version.source).to be_empty
          end
        end
      end

      context 'when saving-and-continuing, then hitting cancel' do
        it 'returns to the resource page' do
          visit dashboard_form_work_versions_path

          FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_draft(metadata)
          FeatureHelpers::DashboardForm.save_and_continue
          FeatureHelpers::DashboardForm.fill_in_work_details(metadata)
          FeatureHelpers::DashboardForm.save_and_continue

          FeatureHelpers::DashboardForm.cancel

          expect(page).to have_content metadata[:title]
        end
      end
    end

    context 'when selecting a work type that uses the scholarly works deposit pathway' do
      it 'shows only the fields for scholarly works' do
        visit dashboard_form_work_versions_path

        FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_scholarly_works_draft(metadata)
        FeatureHelpers::DashboardForm.save_and_continue

        expect(page).not_to have_field('work_version_based_near')
        expect(page).not_to have_field('work_version_source')
        expect(page).not_to have_field('work_version_version_name')
      end

      context 'when saving as draft and exiting' do
        it 'creates a new work with all fields provided' do
          initial_work_count = Work.count

          visit dashboard_form_work_versions_path

          FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_scholarly_works_draft(metadata)
          FeatureHelpers::DashboardForm.save_as_draft_and_exit

          expect(Work.count).to eq(initial_work_count + 1)

          new_work = Work.last
          expect(new_work.work_type).to eq 'article'
          expect(new_work.versions.length).to eq 1

          new_work_version = new_work.versions.last
          expect(page).to have_content(metadata[:title])
          expect(new_work_version.title).to eq metadata[:title]
          expect(new_work_version.version_number).to eq 1

          expect(page).to have_current_path(resource_path(new_work_version.uuid))
          expect(SolrIndexingJob).to have_received(:perform_later).at_least(:once)
        end
      end

      context 'when saving and_continuing' do
        it 'creates a new work with all fields provided' do
          initial_work_count = Work.count

          visit dashboard_form_work_versions_path

          FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_scholarly_works_draft(metadata)
          FeatureHelpers::DashboardForm.save_and_continue
          FeatureHelpers::DashboardForm.fill_in_scholarly_works_work_details(metadata)
          FeatureHelpers::DashboardForm.save_and_continue

          expect(Work.count).to eq(initial_work_count + 1)
          new_work = Work.last
          expect(new_work.work_type).to eq 'article'
          expect(new_work.versions.length).to eq 1

          new_work_version = new_work.versions.last
          expect(new_work_version.version_number).to eq 1
          expect(new_work_version.title).to eq metadata[:title]
          expect(new_work_version.description).to eq metadata[:description]
          expect(new_work_version.publisher_statement).to eq metadata[:publisher_statement]
          expect(new_work_version.published_date).to eq metadata[:published_date]
          expect(new_work_version.keyword).to eq [metadata[:keyword]]
          expect(new_work_version.subtitle).to eq metadata[:subtitle]
          expect(new_work_version.publisher).to eq [metadata[:publisher]]
          expect(new_work_version.subject).to eq [metadata[:subject]]
          expect(new_work_version.language).to eq [metadata[:language]]
          expect(new_work_version.related_url).to eq [metadata[:related_url]]
          expect(new_work_version.identifier).to eq [metadata[:identifier]]

          expect(page).to have_current_path(dashboard_form_contributors_path('work_version', new_work_version))
          expect(SolrIndexingJob).to have_received(:perform_later).at_least(:twice)
        end

        context 'with invalid data' do
          it 'does not save the data and rerenders the form with errors' do
            visit dashboard_form_work_versions_path

            FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_scholarly_works_draft(metadata)
            FeatureHelpers::DashboardForm.save_and_continue
            FeatureHelpers::DashboardForm.fill_in_scholarly_works_work_details(metadata)
            fill_in 'work_version_description', with: ''
            FeatureHelpers::DashboardForm.save_and_continue

            new_work_version = Work.last.versions.last

            expect(page).to have_current_path(dashboard_form_work_version_details_path(new_work_version))
            expect(page).to have_content 'Description is required to publish the work'
            expect(SolrIndexingJob).to have_received(:perform_later).once

            expect(new_work_version.description).to be_nil
            expect(new_work_version.publisher_statement).to be_nil
            expect(new_work_version.published_date).to be_nil
            expect(new_work_version.keyword).to be_empty
            expect(new_work_version.subtitle).to be_nil
            expect(new_work_version.version_name).to be_nil
            expect(new_work_version.publisher).to be_empty
            expect(new_work_version.subject).to be_empty
            expect(new_work_version.language).to be_empty
            expect(new_work_version.related_url).to be_empty
            expect(new_work_version.identifier).to be_empty
            expect(new_work_version.based_near).to be_empty
            expect(new_work_version.source).to be_empty
          end
        end
      end

      context 'when saving-and-continuing, then hitting cancel' do
        it 'returns to the resource page' do
          visit dashboard_form_work_versions_path

          FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_scholarly_works_draft(metadata)
          FeatureHelpers::DashboardForm.save_and_continue
          FeatureHelpers::DashboardForm.fill_in_scholarly_works_work_details(metadata)
          FeatureHelpers::DashboardForm.save_and_continue

          FeatureHelpers::DashboardForm.cancel

          expect(page).to have_content metadata[:title]
        end
      end
    end

    context 'when selecting a work type that uses the data and code deposit pathway' do
      it 'shows only the fields for data and code works' do
        visit dashboard_form_work_versions_path

        FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_data_and_code_draft(metadata)
        FeatureHelpers::DashboardForm.save_and_continue

        expect(page).not_to have_field('publisher_statement')
        expect(page).not_to have_field('work_version_identifier')
      end

      context 'when saving as draft and exiting' do
        it 'creates a new work with all fields provided' do
          initial_work_count = Work.count

          visit dashboard_form_work_versions_path

          FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_data_and_code_draft(metadata)
          FeatureHelpers::DashboardForm.save_as_draft_and_exit

          expect(Work.count).to eq(initial_work_count + 1)

          new_work = Work.last
          expect(new_work.work_type).to eq 'dataset'
          expect(new_work.versions.length).to eq 1

          new_work_version = new_work.versions.last
          expect(page).to have_content(metadata[:title])
          expect(new_work_version.title).to eq metadata[:title]
          expect(new_work_version.version_number).to eq 1

          expect(page).to have_current_path(resource_path(new_work_version.uuid))
          expect(SolrIndexingJob).to have_received(:perform_later).at_least(:once)
        end
      end

      context 'when saving and_continuing' do
        it 'creates a new work with all fields provided' do
          initial_work_count = Work.count

          visit dashboard_form_work_versions_path

          FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_data_and_code_draft(metadata)
          FeatureHelpers::DashboardForm.save_and_continue
          FeatureHelpers::DashboardForm.fill_in_data_and_code_work_details(metadata)
          FeatureHelpers::DashboardForm.save_and_continue

          expect(Work.count).to eq(initial_work_count + 1)
          new_work = Work.last
          expect(new_work.work_type).to eq 'dataset'
          expect(new_work.versions.length).to eq 1

          new_work_version = new_work.versions.last
          expect(new_work_version.version_number).to eq 1
          expect(new_work_version.title).to eq metadata[:title]
          expect(new_work_version.description).to eq metadata[:description]
          expect(new_work_version.published_date).to eq metadata[:published_date]
          expect(new_work_version.keyword).to eq [metadata[:keyword]]
          expect(new_work_version.subtitle).to eq metadata[:subtitle]
          expect(new_work_version.publisher).to eq [metadata[:publisher]]
          expect(new_work_version.subject).to eq [metadata[:subject]]
          expect(new_work_version.language).to eq [metadata[:language]]
          expect(new_work_version.related_url).to eq [metadata[:related_url]]

          expect(page).to have_current_path(dashboard_form_contributors_path('work_version', new_work_version))
          expect(SolrIndexingJob).to have_received(:perform_later).at_least(:twice)
        end

        context 'with invalid data' do
          it 'does not save the data and rerenders the form with errors' do
            visit dashboard_form_work_versions_path

            FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_data_and_code_draft(metadata)
            FeatureHelpers::DashboardForm.save_and_continue
            FeatureHelpers::DashboardForm.fill_in_data_and_code_work_details(metadata)
            fill_in 'work_version_description', with: ''
            FeatureHelpers::DashboardForm.save_and_continue

            new_work_version = Work.last.versions.last

            expect(page).to have_current_path(dashboard_form_work_version_details_path(new_work_version))
            expect(page).to have_content 'Description is required to publish the work'
            expect(SolrIndexingJob).to have_received(:perform_later).once

            expect(new_work_version.description).to be_nil
            expect(new_work_version.published_date).to be_nil
            expect(new_work_version.keyword).to be_empty
            expect(new_work_version.subtitle).to be_nil
            expect(new_work_version.version_name).to be_nil
            expect(new_work_version.publisher).to be_empty
            expect(new_work_version.subject).to be_empty
            expect(new_work_version.language).to be_empty
            expect(new_work_version.related_url).to be_empty
            expect(new_work_version.identifier).to be_empty
            expect(new_work_version.based_near).to be_empty
            expect(new_work_version.source).to be_empty
          end
        end
      end

      context 'when saving-and-continuing, then hitting cancel' do
        it 'returns to the resource page' do
          visit dashboard_form_work_versions_path

          FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_data_and_code_draft(metadata)
          FeatureHelpers::DashboardForm.save_and_continue
          FeatureHelpers::DashboardForm.fill_in_data_and_code_work_details(metadata)
          FeatureHelpers::DashboardForm.save_and_continue

          FeatureHelpers::DashboardForm.cancel

          expect(page).to have_content metadata[:title]
        end
      end
    end
  end

  describe 'The Work Details tab for an existing draft work' do
    let(:work_version) { create :work_version, :draft }
    let(:user) { work_version.work.depositor.user }

    context 'when saving as draft and exiting' do
      it 'creates a new work with all fields provided' do
        initial_work_count = Work.count

        visit dashboard_form_work_version_type_path(work_version)

        FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_draft(metadata)
        FeatureHelpers::DashboardForm.save_as_draft_and_exit

        expect(page).to have_current_path(resource_path(work_version.uuid))
        expect(Work.count).to eq(initial_work_count)
        expect(page).not_to have_button('Request Curation & Save as Draft')

        work_version.reload
        expect(work_version.title).to eq metadata[:title]
        expect(SolrIndexingJob).to have_received(:perform_later).once
      end
    end

    context 'when saving and_continuing' do
      it 'creates a new work with all fields provided' do
        visit dashboard_form_work_version_type_path(work_version)

        FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_draft(metadata)
        FeatureHelpers::DashboardForm.save_and_continue
        FeatureHelpers::DashboardForm.fill_in_work_details(metadata)
        FeatureHelpers::DashboardForm.save_and_continue

        work_version.reload
        expect(work_version.version_number).to eq 2
        expect(work_version.title).to eq metadata[:title]
        expect(work_version.description).to eq metadata[:description]
        expect(work_version.publisher_statement).to eq metadata[:publisher_statement]
        expect(work_version.published_date).to eq metadata[:published_date]
        expect(work_version.keyword).to eq [metadata[:keyword]]
        expect(work_version.subtitle).to eq metadata[:subtitle]
        expect(work_version.version_name).to eq metadata[:version_name]
        expect(work_version.publisher).to eq [metadata[:publisher]]
        expect(work_version.subject).to eq [metadata[:subject]]
        expect(work_version.language).to eq [metadata[:language]]
        expect(work_version.related_url).to eq [metadata[:related_url]]
        expect(work_version.identifier).to eq [metadata[:identifier]]
        expect(work_version.based_near).to eq [metadata[:based_near]]
        expect(work_version.source).to eq [metadata[:source]]

        expect(page).to have_current_path(dashboard_form_contributors_path('work_version', work_version))
        expect(SolrIndexingJob).to have_received(:perform_later).twice
      end
    end

    context 'when navigating away from unsaved changes', js: true do
      it 'warns the user' do
        visit dashboard_form_work_version_type_path(work_version)

        fill_in 'work_version_title', with: "Changed #{metadata[:title]}"

        dismiss_confirm(I18n.t!('dashboard.form.unsaved_changes_prompt')) do
          click_on I18n.t!('dashboard.form.tabs.contributors')
        end

        expect(page).to have_current_path(dashboard_form_work_version_type_path(work_version))

        accept_confirm(I18n.t!('dashboard.form.unsaved_changes_prompt')) do
          click_on I18n.t!('dashboard.form.tabs.contributors')
        end

        expect(page).to have_current_path(dashboard_form_contributors_path('work_version', work_version))
        expect(SolrIndexingJob).not_to have_received(:perform_later)
      end
    end
  end

  describe 'The Contributors tab', js: true do
    let(:work_version) { create :work_version, :draft }
    let(:user) { work_version.work.depositor.user }
    let(:actor) { work_version.work.depositor }

    context 'with an initial draft version' do
      it 'includes the current user as a creator and adds additional contributors' do
        visit dashboard_form_contributors_path('work_version', work_version)

        expect(work_version.creators).to be_empty

        within('#creators') do
          expect(page).to have_content('CREATOR 1')
          expect(find_field('Display Name').value).to eq("#{actor.given_name} #{actor.surname}")
          expect(page).to have_field('Given Name')
          expect(page).to have_field('Family Name')
          expect(page).to have_field('Email')
          expect(page).to have_content("Access Account: #{actor.psu_id}".upcase)
        end

        expect(page).not_to have_button('Request Curation & Save as Draft')

        fill_in 'work_version_contributor', with: metadata[:contributor]

        FeatureHelpers::DashboardForm.save_and_continue

        work_version.reload
        expect(work_version.creators.map(&:actor)).to contain_exactly(actor)
        expect(work_version.creators.map(&:display_name)).to contain_exactly(actor.display_name)
        expect(work_version.contributor).to eq [metadata[:contributor]]

        expect(page).to have_current_path(dashboard_form_files_path(work_version))
        expect(SolrIndexingJob).to have_received(:perform_later).once
      end
    end

    context 'when adding additional users from Penn State', :vcr do
      it 'inserts the Penn State person as a creator into the form' do
        visit dashboard_form_contributors_path('work_version', work_version)

        expect(work_version.creators).to be_empty

        within('#creators') do
          expect(page).to have_content('CREATOR 1')
          expect(page).to have_field('Display Name', count: 1)
        end

        FeatureHelpers::DashboardForm.search_creators('wead')

        within('.algolia-autocomplete') do
          expect(page).to have_content('Adam Wead')
          expect(page).to have_content('Amy Weader')
          expect(page).to have_content('Nathan Andrew Weader')
        end

        find('#search-creators').set("\n")

        within('#creators') do
          expect(page).to have_content('CREATOR 1')
          expect(page).to have_content('CREATOR 2')
          expect(page).to have_field('Display Name', count: 2)
          expect(page).to have_content('Access Account: agw13'.upcase)
        end

        FeatureHelpers::DashboardForm.save_and_continue

        work_version.reload
        expect(work_version.creators[0].actor).to be_present
        expect(work_version.creators[0].display_name).to eq(actor.display_name)
        expect(work_version.creators[1].actor).to be_present
        expect(work_version.creators[1].display_name).to eq('Adam Wead')

        expect(page).to have_current_path(dashboard_form_files_path(work_version))
        expect(SolrIndexingJob).to have_received(:perform_later).once
      end
    end

    context 'when adding additional users with an orcid id', :vcr do
      it 'inserts the Orcid person as a creator into the form' do
        visit dashboard_form_contributors_path('work_version', work_version)

        expect(work_version.creators).to be_empty

        within('#creators') do
          expect(page).to have_content('CREATOR 1')
          expect(page).to have_field('Display Name', count: 1)
        end

        FeatureHelpers::DashboardForm.search_creators('0000-0001-8485-6532')

        within('.algolia-autocomplete') do
          expect(page).to have_content('Adam Wead')
        end

        find_all('.aa-suggestion').first.click

        within('#creators') do
          expect(page).to have_content('CREATOR 1')
          expect(page).to have_content('CREATOR 2')
          expect(page).to have_field('Display Name', count: 2)
          expect(page).to have_content('ORCID: 0000-0001-8485-6532')
        end

        FeatureHelpers::DashboardForm.save_and_continue

        work_version.reload
        expect(work_version.creators[0].actor).to be_present
        expect(work_version.creators[0].display_name).to eq(actor.display_name)
        expect(work_version.creators[1].actor).to be_present
        expect(work_version.creators[1].display_name).to eq('Dr. Adam Wead')

        expect(page).to have_current_path(dashboard_form_files_path(work_version))
        expect(SolrIndexingJob).to have_received(:perform_later).once
      end
    end

    context 'when adding existing actors from Scholarsphere', :vcr do
      # Use a fixed surname so we can record a consistent VCR response from Penn State's identity service
      let!(:existing_actor) { create(:actor, surname: 'Doofus') }

      it 'inserts the local Scholarsphere actor as a creator into the form' do
        visit dashboard_form_contributors_path('work_version', work_version)

        expect(work_version.creators).to be_empty
        within('#creators') do
          expect(page).to have_content('CREATOR 1')
          expect(page).to have_field('Display Name', count: 1)
        end

        FeatureHelpers::DashboardForm.search_creators(existing_actor.surname)

        within('.algolia-autocomplete') do
          expect(page).to have_content(existing_actor.display_name)
        end

        find_all('.aa-suggestion').first.click

        within('#creators') do
          expect(page).to have_content('CREATOR 1')
          expect(page).to have_content('CREATOR 2')
          expect(page).to have_field('Display Name', count: 2)
          expect(page).to have_content("Access Account: #{existing_actor.psu_id}".upcase)
        end

        FeatureHelpers::DashboardForm.save_and_continue

        work_version.reload
        expect(work_version.creators[0].actor).to be_present
        expect(work_version.creators[0].display_name).to eq(actor.display_name)
        expect(work_version.creators[1].actor).to be_present
        expect(work_version.creators[1].display_name).to eq(existing_actor.display_name)

        expect(page).to have_current_path(dashboard_form_files_path(work_version))
        expect(SolrIndexingJob).to have_received(:perform_later).once
      end
    end

    context 'when the creator is not found', :vcr do
      let(:metadata) { attributes_for(:actor) }

      it 'creates a new one and enters it into the form' do
        visit dashboard_form_contributors_path('work_version', work_version)

        expect(work_version.creators).to be_empty
        within('#creators') do
          expect(page).to have_content('CREATOR 1')
          expect(page).to have_field('Display Name', count: 1)
        end

        FeatureHelpers::DashboardForm.search_creators('nobody')

        within('.algolia-autocomplete') do
          expect(page).to have_content('No results')
        end

        find_all('.aa-suggestion').first.click

        within('#creators') do
          expect(page).to have_content('CREATOR 1')
          expect(page).to have_content('CREATOR 2')
          expect(page).to have_field('Display Name', count: 2)
          expect(page).to have_field('Display Name', with: 'nobody')
          expect(page).to have_content('UNIDENTIFIED')
        end

        within(page.find_all('.nested-fields').last) do
          fill_in('Display Name', with: "#{metadata[:given_name]} #{metadata[:surname]}")
          fill_in('Given Name', with: metadata[:given_name])
          fill_in('Family Name', with: metadata[:surname])
          fill_in('Email', with: metadata[:email])
        end

        FeatureHelpers::DashboardForm.save_and_continue

        work_version.reload
        expect(work_version.creators[0].actor).to be_present
        expect(work_version.creators[0].display_name).to eq(actor.display_name)
        expect(work_version.creators[1].actor).not_to be_present
        expect(work_version.creators[1].given_name).to eq(metadata[:given_name])
        expect(work_version.creators[1].surname).to eq(metadata[:surname])

        expect(page).to have_current_path(dashboard_form_files_path(work_version))
        expect(SolrIndexingJob).to have_received(:perform_later).once
      end
    end

    context 'when removing creators from an existing draft' do
      let(:work_version) { create :work_version, :draft, :with_creators, creator_count: 2 }
      let(:creators) { work_version.creators }

      it 'removes the creator from the work' do
        visit dashboard_form_contributors_path('work_version', work_version)

        expect(work_version.creators.map(&:surname)).to eq(creators.map(&:surname))
        within('#creators') do
          expect(page).to have_content('CREATOR 1')
          expect(page).to have_content('CREATOR 2')
          expect(page).to have_field('Display Name', count: 2)
        end

        page.find_all('.remove_fields').first.click
        within('#creators') do
          expect(page).to have_content('CREATOR 1')
          expect(page).not_to have_content('CREATOR 2')
          expect(page).to have_field('Display Name', count: 1)
        end

        FeatureHelpers::DashboardForm.save_and_continue

        expect(work_version.reload.creators.map(&:surname)).to contain_exactly(creators.last.surname)
        expect(page).to have_current_path(dashboard_form_files_path(work_version))
        expect(SolrIndexingJob).to have_received(:perform_later).once
      end
    end

    context 'when re-ordering creators' do
      let(:work_version) { create :work_version, :draft, :with_creators, creator_count: 2 }

      before do
        creator_a, creator_b = work_version.creators

        creator_a.update!(display_name: 'Creator A', position: 1)
        creator_b.update!(display_name: 'Creator B', position: 2)
      end

      it 'saves the creator ordering' do
        visit dashboard_form_contributors_path('work_version', work_version)

        # Sanity Check
        expect(work_version.reload.creators.map(&:display_name)).to eq(['Creator A', 'Creator B'])

        page.find_all('.js-move-down').first.click
        FeatureHelpers::DashboardForm.save_and_continue

        expect(work_version.reload.creators.map(&:display_name)).to eq(['Creator B', 'Creator A'])
        expect(SolrIndexingJob).to have_received(:perform_later).once
      end
    end
  end

  describe 'The Files tab', js: true do
    let(:work_version) { create :work_version, :draft }
    let(:user) { work_version.work.depositor.user }

    it 'works' do
      visit dashboard_form_files_path(work_version)

      # Upload a file
      FeatureHelpers::DashboardForm.upload_file(Rails.root.join('spec', 'fixtures', 'image.png'))
      within('.uppy-Dashboard-files') do
        expect(page).to have_content('image.png')
      end

      # Save, reload the page, and ensure that it's now in the files table
      FeatureHelpers::DashboardForm.save_as_draft_and_exit

      # Once for the work version, twice for the file. The second call for the file is most likely the promotion job.
      expect(SolrIndexingJob).to have_received(:perform_later).thrice

      visit dashboard_form_files_path(work_version)

      within('.table') do
        expect(page).to have_content('image.png')
        expect(page).to have_content('62.5 KB')
        expect(page).to have_content('image/png')
      end

      # Try to re-upload the same file again
      page
        .all('.uppy-Dashboard-input', visible: false)
        .first
        .attach_file(Rails.root.join('spec', 'fixtures', 'image.png'))

      within('.uppy-Informer') do
        until page.has_content?('Error: image.png already exists in this version')
          sleep 0.1
        end
      end

      expect(page).not_to have_button('Request Curation & Save as Draft')
    end

    context 'when a work is in the data & code pathway' do
      let(:work) { create :work, versions_count: 1 }
      let(:work_version) { work.versions.first }
      let(:user) { work.depositor.user }

      it 'displays helper text' do
        visit dashboard_form_files_path(work_version)

        expect(page).to have_content(I18n.t!('dashboard.form.details.readme'))
      end
    end

    context 'when a work is not in the data & code pathway' do
      let(:work) { create :work, :article, versions_count: 1 }
      let(:work_version) { work.versions.first }
      let(:user) { work.depositor.user }

      it 'does not display helper text' do
        visit dashboard_form_files_path(work_version)

        expect(page).not_to have_content(I18n.t!('dashboard.form.details.readme'))
      end
    end
  end

  describe 'The Publish tab' do
    context 'when submitting the form with publication errors' do
      let(:user) { work_version.work.depositor.user }
      let(:work_version) { create :work_version, :draft }

      it 'does NOT publish the work, but DOES save the changes to the draft' do
        visit dashboard_form_publish_path(work_version)

        fill_in 'work_version_published_date', with: 'this is not a valid date'
        FeatureHelpers::DashboardForm.publish

        expect(SolrIndexingJob).not_to have_received(:perform_later)

        expect(page).to have_current_path(dashboard_form_publish_path(work_version))

        within '#error_explanation' do
          expect(page).to have_content(I18n.t!('errors.messages.invalid_edtf'))
        end

        within '.footer--actions' do
          expect(page).to have_button(I18n.t!('dashboard.form.actions.publish'))
        end

        work_version.reload
        expect(work_version).not_to be_published
        expect(work_version.published_date).to eq 'this is not a valid date'
        expect(work_version.published_at).to be_nil
      end
    end

    context 'with a non v1 draft version' do
      let(:user) { work_version.work.depositor.user }
      let(:work_version) { create :work_version }

      it 'does not display visibility fields' do
        visit dashboard_form_publish_path(work_version)

        expect(page).not_to have_content('Penn State Only')
        expect(page).not_to have_content('Embargo')
      end
    end

    context 'with a v1 draft version' do
      let(:work) { create :work, versions_count: 1, has_draft: true, work_type: 'article' }
      let(:work_version) { work.versions.first }
      let(:user) { work.depositor.user }

      it 'displays visibility fields' do
        visit dashboard_form_publish_path(work_version)

        expect(page).to have_content('Penn State Only')
        expect(page).to have_content('Embargo')
      end
    end

    context 'with a work that uses the general deposit pathway' do
      let(:work) { create :work, versions_count: 1, work_type: 'audio' }
      let(:work_version) { work.versions.first }
      let(:user) { work.depositor.user }

      it 'shows all of the work details fields' do
        visit dashboard_form_publish_path(work_version)

        expect(page).to have_field('work_version_based_near')
        expect(page).to have_field('work_version_source')
        expect(page).to have_field('work_version_version_name')
        expect(page).to have_field('work_version_publisher_statement')
        expect(page).to have_field('work_version_work_attributes_visibility_open')
        expect(page).to have_field('work_version_work_attributes_visibility_authenticated')
      end
    end

    context 'with a work that uses the scholarly works deposit pathway' do
      let(:work) { create :work, :article, versions_count: 1 }
      let(:work_version) { work.versions.first }
      let(:user) { work.depositor.user }

      it 'shows only the fields for a scholarly work' do
        visit dashboard_form_publish_path(work_version)

        expect(page).not_to have_field('work_version_based_near')
        expect(page).not_to have_field('work_version_source')
        expect(page).not_to have_field('work_version_version_name')
        expect(page).to have_field('work_version_publisher_statement')
        expect(page).to have_field('work_version_work_attributes_visibility_open')
        expect(page).to have_field('work_version_work_attributes_visibility_authenticated')
      end
    end

    context 'with a work that uses the data & code deposit pathway' do
      let(:work) { create :work, versions_count: 1 }
      let(:work_version) { work.versions.first }
      let(:user) { work.depositor.user }

      it 'shows only the fields for a data & code work' do
        visit dashboard_form_publish_path(work_version)

        expect(page).to have_field('work_version_based_near')
        expect(page).to have_field('work_version_source')
        expect(page).to have_field('work_version_version_name')
        expect(page).not_to have_field('work_version_publisher_statement')
        expect(page).not_to have_field('work_version_identifier')
        expect(page).not_to have_field('work_version_work_attributes_visibility_open')
        expect(page).not_to have_field('work_version_work_attributes_visibility_authenticated')
      end
    end
  end

  describe 'Publishing a new work from end-to-end', js: true do
    let(:different_metadata) { attributes_for(:work_version, :with_complete_metadata) }

    it 'routes the user through the workflow' do
      visit dashboard_form_work_versions_path

      FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_draft(metadata)
      FeatureHelpers::DashboardForm.save_and_continue
      FeatureHelpers::DashboardForm.fill_in_work_details(metadata)
      FeatureHelpers::DashboardForm.save_and_continue

      # Ensure one creator is pre-filled with the User's Actor
      actor = user.reload.actor
      within('#creators') do
        expect(page).to have_content('CREATOR 1')
        expect(find_field('Display Name').value).to eq("#{actor.given_name} #{actor.surname}")
        expect(page).to have_field('Given Name')
        expect(page).to have_field('Family Name')
        expect(page).to have_field('Email')
        expect(page).to have_content("Access Account: #{actor.psu_id}".upcase)
      end

      FeatureHelpers::DashboardForm.save_and_continue

      FeatureHelpers::DashboardForm.upload_file(Rails.root.join('spec', 'fixtures', 'image.png'))
      within('.uppy-Dashboard-files') do
        expect(page).to have_content('image.png')
      end
      FeatureHelpers::DashboardForm.save_and_continue

      # Don't yell at them for something they haven't seen yet
      expect(page).not_to have_selector('div#error_explanation')

      # On the review page, change all the details metadata to ensure the params
      # are submitted correctly
      expect_any_instance_of(WorkVersion).to receive(:set_thumbnail_selection).once
      fill_in 'work_version_title', with: different_metadata[:title]
      FeatureHelpers::DashboardForm.fill_in_work_details(different_metadata)
      FeatureHelpers::DashboardForm.fill_in_publishing_details(metadata)
      FeatureHelpers::DashboardForm.publish

      #
      # Load out the new published work and ensure that all is well
      #
      work = Work.last
      version = work.versions.first

      expect(page).to have_current_path(resource_path(work.uuid))
      expect(page).to have_selector('h1', text: version.title)

      expect(version).to be_published
      expect(version.published_at).to be_present.and be_within(2.seconds).of(Time.zone.now)
      expect(work.visibility).to eq(Permissions::Visibility::OPEN)
      expect(version.version_number).to eq 1
      expect(version.title).to eq different_metadata[:title]
      expect(version.description).to eq different_metadata[:description]
      expect(version.publisher_statement).to eq different_metadata[:publisher_statement]
      expect(version.published_date).to eq different_metadata[:published_date]
      expect(version.keyword).to eq [different_metadata[:keyword]]
      expect(version.publisher).to eq [different_metadata[:publisher]]
      expect(version.subject).to eq [different_metadata[:subject]]
      expect(version.language).to eq [different_metadata[:language]]
      expect(version.related_url).to eq [different_metadata[:related_url]]
      expect(version.rights).to eq metadata[:rights]

      expect(version.creators.length).to eq 1
      expect(version.creators.first.display_name).to eq user.actor.display_name
    end
  end

  describe 'Publishing a Penn State only work', js: true do
    let(:different_metadata) { attributes_for(:work_version, :with_complete_metadata) }
    let(:correct_rights) { WorkVersion::Licenses::ids_for_authorized_visibility.first }
    let(:incorrect_rights) { (WorkVersion::Licenses.ids - WorkVersion::Licenses::ids_for_authorized_visibility).first }

    it 'routes the user through the workflow' do
      visit dashboard_form_work_versions_path

      FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_draft(metadata)
      FeatureHelpers::DashboardForm.save_and_continue
      FeatureHelpers::DashboardForm.fill_in_work_details(metadata)
      FeatureHelpers::DashboardForm.save_and_continue

      FeatureHelpers::DashboardForm.save_and_continue

      FeatureHelpers::DashboardForm.upload_file(Rails.root.join('spec', 'fixtures', 'image.png'))
      within('.uppy-Dashboard-files') do
        expect(page).to have_content('image.png')
      end
      FeatureHelpers::DashboardForm.save_and_continue

      # Don't yell at them for something they haven't seen yet
      expect(page).not_to have_selector('div#error_explanation')

      # On the review page, change all the details metadata to ensure the params
      # are submitted correctly
      fill_in 'work_version_title', with: different_metadata[:title]
      FeatureHelpers::DashboardForm.fill_in_work_details(different_metadata)

      # Pick the wrong license
      FeatureHelpers::DashboardForm.fill_in_publishing_details(
        metadata.merge(rights: incorrect_rights),
        visibility: Permissions::Visibility::AUTHORIZED
      )
      FeatureHelpers::DashboardForm.publish

      # Ensure that there is an error on the rights
      within 'div#error_explanation' do
        expect(page).to have_content(
          I18n.t!(
            'activerecord.errors.models.work_version.attributes.rights.incompatible_license_for_authorized_visibility'
          )
        )
      end

      # Pick the correct license
      FeatureHelpers::DashboardForm.fill_in_publishing_details(
        metadata.merge(rights: correct_rights),
        visibility: Permissions::Visibility::AUTHORIZED
      )
      FeatureHelpers::DashboardForm.publish

      #
      # Load out the new published work and ensure that all is well
      #
      work = Work.last
      version = work.versions.first

      expect(page).to have_current_path(resource_path(work.uuid))
      expect(page).to have_selector('h1', text: version.title)

      expect(version).to be_published
      expect(work.visibility).to eq(Permissions::Visibility::AUTHORIZED)
      expect(version.version_number).to eq 1
      expect(version.title).to eq different_metadata[:title]
      expect(version.description).to eq different_metadata[:description]
      expect(version.publisher_statement).to eq different_metadata[:publisher_statement]
      expect(version.published_date).to eq different_metadata[:published_date]
      expect(version.keyword).to eq [different_metadata[:keyword]]
      expect(version.publisher).to eq [different_metadata[:publisher]]
      expect(version.subject).to eq [different_metadata[:subject]]
      expect(version.language).to eq [different_metadata[:language]]
      expect(version.related_url).to eq [different_metadata[:related_url]]
      expect(version.rights).to eq correct_rights

      expect(version.creators.length).to eq 1
      expect(version.creators.first.display_name).to eq user.actor.display_name
    end
  end

  describe 'Editing a published work' do
    let(:work) { create :work, work_type: 'audio' }
    let(:work_version) { create :work_version, :published, work: work }
    let(:invalid_metadata) { attributes_for(:work_version, :with_complete_metadata, description: '') }
    let(:different_metadata) { attributes_for(:work_version, :with_complete_metadata) }
    let(:incorrect_rights) { (WorkVersion::Licenses.ids - WorkVersion::Licenses::ids_for_authorized_visibility).first }
    let(:user) { create(:user, :admin) }

    # RSpec mocks _cumulatively_ record the number of times they've been called,
    # we need a way to say "from this exact point, you should have been called
    # once." We accomplish this by tearing down the mock and setting it back up.
    def mock_solr_indexing_job
      RSpec::Mocks.space.proxy_for(SolrIndexingJob)&.reset

      allow(SolrIndexingJob).to receive(:perform_later).and_call_original
    end

    it 'allows an administrator to update the metadata' do
      visit dashboard_form_publish_path(work_version)

      mock_solr_indexing_job

      # Fill out form with errors to check error handling
      FeatureHelpers::DashboardForm.fill_in_work_details(invalid_metadata)
      FeatureHelpers::DashboardForm.finish

      within '#error_explanation' do
        expect(page).to have_content(I18n.t!('activerecord.errors.models.work_version.attributes.description.blank'))
      end

      within '.footer--actions' do
        expect(page).to have_button(I18n.t!('dashboard.form.actions.finish'))
      end

      # Fill out form properly
      FeatureHelpers::DashboardForm.fill_in_work_details(different_metadata)
      # Note that visibility fields are not editable for published work
      # Pick a license
      FeatureHelpers::DashboardForm.fill_in_publishing_details_published(
        different_metadata.merge(rights: incorrect_rights)
      )
      FeatureHelpers::DashboardForm.finish
      expect(SolrIndexingJob).to have_received(:perform_later).once

      work_version.reload
      expect(work_version.rights).to eq(incorrect_rights)
      expect(work_version.visibility).to eq(Permissions::Visibility::OPEN)
    end
  end

  describe 'Deleting a version' do
    context 'when logged in as a regular user' do
      let(:work_version) { create :work_version, :draft }
      let(:user) { work_version.work.depositor.user }

      it 'allows a user to delete a draft' do
        visit dashboard_form_work_version_details_path(work_version)
        FeatureHelpers::DashboardForm.delete

        expect { work_version.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when logged in as an admin' do
      let(:work_version) { create :work_version, :published }
      let(:user) { create(:user, :admin) }

      it 'hides the delete button on published versions' do
        visit dashboard_form_work_version_details_path(work_version)
        expect {
          FeatureHelpers::DashboardForm.delete
        }.to raise_error(Capybara::ElementNotFound)
      end
    end
  end

  describe 'Requesting curation', js: true do
    let(:user) { work_version.work.depositor.user }
    let(:request_description) { "Select 'Request Curation & Save as Draft' below if you would like ScholarSphere curators to review your work assessing its findability, accessibility, interoperability, and reusability prior to publication (recommended)." }
    let(:publish_description) { "Select 'Publish' if you would like to self-submit your deposit to Scholarsphere and make it immediately public. ScholarSphere curators will review your work after publication. Note, because curatorial review occurs after publication, any changes or updates may result in a versioned work." }

    context 'with a draft eligible for curation request' do
      let(:work_version) { create :work_version, :draft, draft_curation_requested: nil }

      it 'renders buttons for requesting curation and publish and shows helper text explaing requesting curation' do
        visit dashboard_form_publish_path(work_version)

        expect(page).to have_button('Request Curation & Save as Draft')
        expect(page).to have_button('Publish')

        expect(page).to have_content(request_description)
        expect(page).to have_content(publish_description)
      end
    end

    context 'with a draft not eligible for curation request' do
      let(:work) { create :work, :article, versions_count: 1, has_draft: true }
      let(:work_version) { work.versions.first }

      it 'does not render a button for requesting curation but does render publish and does not show helper text about requesting curation' do
        visit dashboard_form_publish_path(work_version)

        expect(page).not_to have_button('Request Curation & Save as Draft')
        expect(page).to have_button('Publish')
        expect(page).not_to have_content(request_description)
      end
    end

    context 'with a draft that already has curation requested' do
      let(:work_version) { create :work_version, :dataset_able_to_be_published, draft_curation_requested: true }
      let(:curation_requested) { 'Curation has been requested. We will notify you when curation is complete and your work is ready to be published. If you have any questions in the meantime, please contact ScholarSphere curators via our ' }

      context 'when user is an admin' do
        let(:user) { create(:user, :admin) }

        it 'allows admin to publish' do
          visit dashboard_form_publish_path(work_version)

          expect(page).to have_button('Publish')

          check 'I have read and agree to the deposit agreement.'
          click_on 'Publish'

          expect(work_version.reload.aasm_state).to eq 'published'
        end
      end

      context 'when user is not an admin' do
        it 'does not render buttons for requesting curation or publish & shows text that curation has been requested' do
          visit dashboard_form_publish_path(work_version)

          expect(page).not_to have_button('Request Curation & Save as Draft')
          expect(page).not_to have_button('Publish')
          expect(page).to have_content(curation_requested)
          expect(page).to have_link('contact form')
        end
      end
    end

    context 'when curation is successfully requested' do
      let(:work_version) { create :work_version, :dataset_able_to_be_published, draft_curation_requested: nil }

      before do
        allow(CurationTaskExporter).to receive(:call).with(work_version.id)
      end

      it 'creates a Submission' do
        visit dashboard_form_publish_path(work_version)

        check 'I have read and agree to the deposit agreement.'

        click_on 'Request Curation & Save as Draft'

        work_version.reload

        expect(CurationTaskExporter).to have_received(:call).with(work_version.id)
        expect(work_version.draft_curation_requested).to be true
      end
    end

    context 'when an error occurs within the curation exporter' do
      let(:work_version) { create :work_version, :dataset_able_to_be_published, draft_curation_requested: nil }

      before { allow(CurationTaskExporter).to receive(:call).with(work_version.id).and_raise(CurationTaskExporter::CurationError) }

      it 'saves changes to the work version and displays an error flash message' do
        visit dashboard_form_publish_path(work_version)

        fill_in 'work_version_title', with: ''
        fill_in 'work_version_title', with: 'Changed Title'
        check 'I have read and agree to the deposit agreement.'

        click_on 'Request Curation & Save as Draft'

        within('.alert-danger') do
          expect(page).to have_content('There was an error with your curation request')
        end

        work_version.reload
        expect(work_version.title).to eq('Changed Title')
        expect(work_version.draft_curation_requested).not_to be true
      end
    end

    context 'when there is a validation error' do
      let(:work_version) { create :work_version, :dataset_able_to_be_published, draft_curation_requested: nil }

      before { allow(CurationTaskExporter).to receive(:call).with(work_version.id) }

      it 'does not call the curation task exporter' do
        visit dashboard_form_publish_path(work_version)

        fill_in 'work_version_published_date', with: 'this is not a valid date'
        check 'I have read and agree to the deposit agreement.'

        click_on 'Request Curation & Save as Draft'

        expect(CurationTaskExporter).not_to have_received(:call).with(work_version.id)

        within '#error_explanation' do
          expect(page).to have_content(I18n.t!('errors.messages.invalid_edtf'))
        end

        within '.footer--actions' do
          expect(page).to have_button(I18n.t!('dashboard.form.actions.request_curation'))
        end

        work_version.reload
        expect(work_version).not_to be_published
        expect(work_version.published_date).to eq 'this is not a valid date'
        expect(work_version.draft_curation_requested).to eq false
      end
    end
  end
end
