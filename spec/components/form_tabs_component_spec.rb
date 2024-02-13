# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FormTabsComponent, type: :component do
  let(:node) { render_inline(described_class.new(resource: resource, current_controller: current_controller)) }
  let(:tabs) { node.css('.nav-tabs').first }

  context 'with a work version that has NOT been persisted' do
    let(:current_controller) { 'work_version_details' }
    let(:resource) { build :work_version }

    it 'does NOT render the tabs as links' do
      expect(tabs.css('a')).to be_empty
      expect(tabs.css('.nav-item.disabled').length).to eq 5
    end

    it "renders the current controller's tab as active" do
      expect(tabs.css('.nav-item.active').text).to eq I18n.t!('dashboard.form.tabs.work_version_details')
    end
  end

  context 'with a work version has been persisted' do
    let(:current_controller) { 'work_version_details' }
    let(:resource) { build_stubbed :work_version }

    it 'renders the inactive tabs as links' do
      expect(tabs.css('a.nav-item').length).to eq 4
      expect(tabs.css('a.nav-item').map(&:text)).not_to include(I18n.t!('dashboard.form.tabs.work_version_details'))
    end

    it 'renders the active tab as a non-link' do
      expect(tabs.css('.nav-item.active').text).to eq I18n.t!('dashboard.form.tabs.work_version_details')
    end
  end

  context 'with a collection that has NOT been persisted' do
    let(:current_controller) { 'collection_details' }
    let(:resource) { build :collection }

    it 'does NOT render the tabs as links' do
      expect(tabs.css('a')).to be_empty
      expect(tabs.css('.nav-item.disabled').length).to eq 3
    end

    it "renders the current controller's tab as active" do
      expect(tabs.css('.nav-item.active').text).to eq I18n.t!('dashboard.form.tabs.collection_details')
    end
  end

  context 'with a collection has been persisted' do
    let(:current_controller) { 'collection_details' }
    let(:resource) { build_stubbed :collection }

    it 'renders the inactive tabs as links' do
      expect(tabs.css('a.nav-item').length).to eq 2
      expect(tabs.css('a.nav-item').map(&:text)).not_to include(I18n.t!('dashboard.form.tabs.collection_details'))
    end

    it 'renders the active tab as a non-link' do
      expect(tabs.css('.nav-item.active').text).to eq I18n.t!('dashboard.form.tabs.collection_details')
    end
  end
end
