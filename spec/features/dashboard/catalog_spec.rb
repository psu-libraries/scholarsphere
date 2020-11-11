# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard catalog page', :inline_jobs do
  let(:user) { create(:user) }
  let(:outsider) { create(:user) }

  context 'when the user has NO deposited works' do
    it 'displays an informational page to the user', with_user: :user do
      visit(dashboard_root_path)
      expect(page.title).to eq('ScholarSphere')

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

  context 'when the user has only editable works, and none that they own or have deposited' do
    let!(:restricted_work) { create(:work, has_draft: true, depositor: outsider.actor) }
    let!(:editable_work) { create(:work, has_draft: true, depositor: outsider.actor, edit_users: [user]) }

    it "displays the user's editable works", with_user: :user do
      visit(dashboard_root_path)

      expect(user.actor.deposited_works).to be_empty
      expect(page).to have_link('Dashboard', class: 'disabled')
      expect(page).not_to have_text('What is my dashboard?')
      expect(page).not_to have_text('Get Started')

      expect(page.first('.card-title').text).to eq(editable_work.versions.first.title)
      expect(page).not_to have_text(restricted_work.versions.first.title)
      click_link(editable_work.versions.first.title)
      expect(page).to have_link('Edit V1')
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
end
