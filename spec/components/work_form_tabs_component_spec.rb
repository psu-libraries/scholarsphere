# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkFormTabsComponent, type: :component do
  let(:node) { render_inline(described_class.new(work_version: work_version, current_controller: current_controller)) }
  let(:current_controller) { 'details' }
  let(:tabs) { node.css('.nav-tabs').first }

  context 'when the work version has NOT been persisted' do
    let(:work_version) { build :work_version }

    it 'does NOT render the tabs as links' do
      expect(tabs.css('a')).to be_empty
      expect(tabs.css('.nav-item.disabled').length).to eq 4
    end

    it "renders the current controller's tab as active" do
      expect(tabs.css('.nav-item.active').text).to eq I18n.t('dashboard.work_form.tabs.details')
    end
  end

  context 'when the work version has been persisted' do
    let(:work_version) { build_stubbed :work_version }

    it 'renders the inactive tabs as links' do
      expect(tabs.css('a.nav-item').length).to eq 3
      expect(tabs.css('a.nav-item').map(&:text)).not_to include(I18n.t('dashboard.work_form.tabs.details'))
    end

    it 'renders the active tab as a non-link' do
      expect(tabs.css('.nav-item.active').text).to eq I18n.t('dashboard.work_form.tabs.details')
    end
  end
end
