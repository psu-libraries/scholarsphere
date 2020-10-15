# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard catalog page', :inline_jobs do
  let(:user) { create(:user) }
  let(:outsider) { create(:user) }

  context 'when the user has NO deposited works' do
    it 'displays an informational page to the user', with_user: :user do
      visit(dashboard_root_path)

      expect(page).to have_link('Dashboard', class: 'disabled')
      expect(page).to have_selector('h4', text: 'What is my dashboard?')
      expect(page).to have_selector('h4', text: 'Get Started')
      expect(page).to have_link('Create New Work')
    end
  end

  context 'when the user has deposited works' do
    let(:work_versions) do
      Work
        .where(depositor: user.actor)
        .map(&:latest_version)
        .compact
        .sort_by!(&:updated_at)
        .reverse
    end

    let(:title_cards) do
      page.find_all('.card-title')
    end

    before do
      Array.new(10).map do
        FactoryBot.create(:work, depositor: user.actor, versions_count: rand(1..5), has_draft: (rand(1..2) == 1))
      end

      Array.new(10).map do
        FactoryBot.create(:work, depositor: outsider.actor, versions_count: rand(1..5), has_draft: (rand(1..2) == 1))
      end
    end

    it "displays the depositor's works", with_user: :user do
      visit(dashboard_root_path)
      click_link('100 per page')

      expect(page).to have_content("1 - #{work_versions.count} of #{work_versions.count}")

      # Ensure most recently updated work version is listed first
      expect(page.first('.card-title').text).to eq(work_versions.first.title)

      click_link(work_versions.first.title)
      expect(page).to have_content(work_versions.first.title)
    end
  end

  context "when the user's search returns no results" do
    before { create(:work, depositor: user.actor, has_draft: true) }

    it 'displays no search results', with_user: :user do
      visit(dashboard_root_path(q: 'asdfasdfasdfasdfasdfasdfasdf'))

      expect(page).to have_selector('h4', text: I18n.t('dashboard.catalog.zero_results.info.heading'))
      expect(page).to have_content(I18n.t('dashboard.catalog.zero_results.info.content'))
    end
  end

  context 'when the user has a published work' do
    let!(:work) { create(:work, depositor: user.actor, versions_count: 3, has_draft: false) }

    it 'enables them to create a new version', with_user: :user do
      visit(dashboard_root_path)

      within('.card-actions') do
        expect(page).to have_content('V3')
        expect(page).to have_content('published')
        expect(page).not_to have_link('delete')
        expect(page).not_to have_link('edit')
        click_link('create_new_folder')
      end

      expect(page).to have_content('Edit Draft Work')
      expect(page).to have_content('Work version was successfully created')
      expect(work.versions.count).to eq(4)
    end
  end

  context 'when deleting draft versions WITH previous published versions' do
    let!(:work) { create(:work, depositor: user.actor, versions_count: 3, has_draft: true) }

    it 'deletes the draft version and returns to the dashboard', with_user: :user do
      visit(dashboard_root_path)

      expect(work.versions.count).to eq(3)

      within('.card-actions') do
        expect(page).to have_content('V3')
        expect(page).to have_content('draft')
        expect(page).to have_link('edit')
        expect(page).not_to have_link('create_new_folder')
        click_link('delete')
      end

      expect(page).to have_content('Work version was successfully destroyed.')
      expect(work.versions.count).to eq(2)

      within('.card-actions') do
        expect(page).to have_content('V2')
        expect(page).to have_content('published')
        expect(page).not_to have_link('delete')
        expect(page).not_to have_link('edit')
        click_link('create_new_folder')
      end
    end
  end

  context 'when deleting draft versions WITHOUT previous published versions' do
    let!(:work) { create(:work, depositor: user.actor, has_draft: true) }

    it 'deletes the draft version, as well as the work, and returns to the dashboard', with_user: :user do
      visit(dashboard_root_path)

      expect(work.versions.count).to eq(1)

      within('.card-actions') do
        expect(page).to have_content('V1')
        expect(page).to have_content('draft')
        expect(page).to have_link('edit')
        expect(page).not_to have_link('create_new_folder')
        click_link('delete')
      end

      expect(page).to have_content('Work version was successfully destroyed.')
      expect(page).not_to have_selector('.card-title')
      expect(Work.exists?(work.id)).to be(false)
    end
  end
end
