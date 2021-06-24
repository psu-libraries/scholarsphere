# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditResourceButton, type: :component do
  include Rails.application.routes.url_helpers

  let(:button) { node.css('a').first }

  context 'when the resource is a work version' do
    let(:work) { WorkDecorator.new(create(:work, versions_count: 2, has_draft: true)) }
    let(:v1) { work.decorated_versions.first }
    let(:v2) { work.decorated_versions.last }

    let(:mock_helpers) { spy 'MockHelpers', policy: mock_policy }
    let(:mock_policy) { instance_spy 'WorkVersionPolicy', new?: true }

    let(:node) { render_inline(described_class.new(resource: v1, policy: mock_policy)) }

    context 'when a work has an existing draft' do
      specify do
        expect(button.attributes['href'].value).to eq "/dashboard/form/work_versions/#{v2.id}/details"
        expect(button.attributes['data-method']).to be_nil
        expect(button.text).to include 'Update Work'
      end
    end

    context 'when a work does NOT have an existing draft' do
      let(:work) { WorkDecorator.new(create(:work, versions_count: 2, has_draft: false)) }

      specify do
        expect(v1.work.draft_version).to be_nil
        expect(button.attributes['href'].value).to eq "/dashboard/works/#{work.id}/work_versions"
        expect(button.attributes['data-method'].value).to eq 'post'
        expect(button.text).to include 'Update Work'
      end
    end
  end

  context 'when the resource is a collection' do
    let(:collection) { CollectionDecorator.new(create(:collection)) }
    let(:node) { render_inline(described_class.new(resource: collection, policy: nil)) }

    specify do
      expect(button.attributes['href'].value).to eq dashboard_form_collection_details_path(collection.id)
      expect(button.attributes['data-method']).to be_nil
      expect(button.text).to include 'Update Collection'
    end
  end
end
