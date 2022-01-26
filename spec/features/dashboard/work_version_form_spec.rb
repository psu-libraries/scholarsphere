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
    context 'when saving as draft and exiting' do
      it 'creates a new work with all fields provided' do
        initial_work_count = Work.count

        visit dashboard_form_work_versions_path

        FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_draft(metadata)
        FeatureHelpers::DashboardForm.save_as_draft_and_exit

        expect(Work.count).to eq(initial_work_count + 1)

        new_work = Work.last
        expect(new_work.work_type).to eq Work::Types.default
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

        FeatureHelpers::DashboardForm.fill_in_work_details(metadata)
        FeatureHelpers::DashboardForm.save_and_continue

        expect(Work.count).to eq(initial_work_count + 1)
        new_work = Work.last
        expect(new_work.work_type).to eq Work::Types.default
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
        expect(SolrIndexingJob).to have_received(:perform_later).at_least(:once)
      end
    end

    context 'when saving-and-continuing, then hitting cancel' do
      it 'returns to the resource page' do
        visit dashboard_form_work_versions_path

        FeatureHelpers::DashboardForm.fill_in_work_details(metadata)
        FeatureHelpers::DashboardForm.save_and_continue

        FeatureHelpers::DashboardForm.cancel

        expect(page).to have_content metadata[:title]
      end
    end
  end

  describe 'The Work Details tab for an existing draft work' do
    let(:work_version) { create :work_version, :draft }
    let(:user) { work_version.work.depositor.user }

    context 'when saving as draft and exiting' do
      it 'creates a new work with all fields provided' do
        initial_work_count = Work.count

        visit dashboard_form_work_version_details_path(work_version)

        FeatureHelpers::DashboardForm.fill_in_minimal_work_details_for_draft(metadata)
        FeatureHelpers::DashboardForm.save_as_draft_and_exit

        expect(page).to have_current_path(resource_path(work_version.uuid))
        expect(Work.count).to eq(initial_work_count)

        work_version.reload
        expect(work_version.title).to eq metadata[:title]
        expect(SolrIndexingJob).to have_received(:perform_later).once
      end
    end

    context 'when saving and_continuing' do
      it 'creates a new work with all fields provided' do
        visit dashboard_form_work_version_details_path(work_version)

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
        expect(SolrIndexingJob).to have_received(:perform_later).once
      end
    end

    context 'when navigating away from unsaved changes', js: true do
      it 'warns the user' do
        visit dashboard_form_work_version_details_path(work_version)

        fill_in 'work_version_title', with: "Changed #{metadata[:title]}"

        dismiss_confirm(I18n.t!('dashboard.form.unsaved_changes_prompt')) do
          click_on I18n.t!('dashboard.form.tabs.contributors')
        end

        expect(page).to have_current_path(dashboard_form_work_version_details_path(work_version))

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
    end
  end

  describe 'The Publish tab' do
    let(:work_version) { create :work_version, :draft }
    let(:user) { work_version.work.depositor.user }

    context 'when submitting the form with publication errors' do
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
      end
    end
  end

  describe 'Publising a new work from end-to-end', js: true do
    let(:different_metadata) { attributes_for(:work_version, :with_complete_metadata) }

    it 'routes the user through the workflow' do
      visit dashboard_form_work_versions_path

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

    it 'routes the user through the workflow' do
      visit dashboard_form_work_versions_path

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
      FeatureHelpers::DashboardForm.fill_in_work_details(different_metadata)
      FeatureHelpers::DashboardForm.fill_in_publishing_details(
        metadata,
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
      expect(version.rights).to eq metadata[:rights]

      expect(version.creators.length).to eq 1
      expect(version.creators.first.display_name).to eq user.actor.display_name
    end
  end

  describe 'Editing a published work' do
    let(:work_version) { create :work_version, :published }
    let(:invalid_metadata) { attributes_for(:work_version, :with_complete_metadata, description: '') }
    let(:different_metadata) { attributes_for(:work_version, :with_complete_metadata) }
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
      FeatureHelpers::DashboardForm.fill_in_publishing_details(different_metadata)
      FeatureHelpers::DashboardForm.finish
      expect(SolrIndexingJob).to have_received(:perform_later).once

      work_version.reload
      expect(work_version.rights).to eq(different_metadata[:rights])
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
end
