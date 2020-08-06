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
      Work.where(depositor: user.actor).map(&:latest_version).compact
    end

    before do
      Array.new(10).map do
        FactoryBot.create(:work, depositor: user.actor, versions_count: rand(1..5), has_draft: (rand(1..2) == 1))
      end

      Array.new(10).map do
        FactoryBot.create(:work, depositor: outsider.actor, versions_count: rand(1..5), has_draft: (rand(1..2) == 1))
      end

      FactoryBot.create(:collection, depositor: user.actor)
    end

    it "displays the depositor's works", with_user: :user do
      visit(dashboard_root_path)
      click_link('100 per page')

      expect(page).to have_content("1 - #{work_versions.count} of #{work_versions.count}")
    end
  end
end
