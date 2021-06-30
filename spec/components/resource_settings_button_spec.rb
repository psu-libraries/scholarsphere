# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResourceSettingsButton, type: :component do
  include Rails.application.routes.url_helpers

  let(:button) { node.css('a').first }
  let(:icon) { node.css('i').first }

  context 'when the resource is a work' do
    let(:work) { WorkDecorator.new(create(:work, versions_count: 2, has_draft: true)) }

    let(:node) { render_inline(described_class.new(resource: work)) }

    specify do
      expect(button.attributes['href'].value).to eq edit_dashboard_work_path(work)
      expect(button.attributes['data-method']).to be_nil
      expect(icon.text).to include 'settings'
      expect(button.text).to include 'Work Settings'
    end
  end

  context 'when the resource is a collection' do
    let(:collection) { CollectionDecorator.new(create(:collection)) }
    let(:node) { render_inline(described_class.new(resource: collection, policy: nil)) }

    specify do
      expect(button.attributes['href'].value).to eq edit_dashboard_collection_path(collection)
      expect(button.attributes['data-method']).to be_nil
      expect(icon.text).to include 'settings'
      expect(button.text).to include 'Collection Settings'
    end
  end
end
