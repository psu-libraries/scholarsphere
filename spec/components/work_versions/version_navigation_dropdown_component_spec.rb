# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersions::VersionNavigationDropdownComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new(work: work, current_version: current_version) }
  let(:result) { render_inline(component) }

  let(:mock_helpers) { spy 'MockHelpers', policy: mock_policy }
  let(:mock_policy) { instance_spy 'WorkVersionPolicy', navigable?: true }

  before do
    allow(component).to receive(:helpers).and_return(mock_helpers)
  end

  context 'when the work has no draft' do
    let(:work) { WorkDecorator.new(build(:work, versions_count: 2, has_draft: false)) }
    let(:current_version) { v2 }

    let(:v1) { work.decorated_versions.first }
    let(:v2) { work.decorated_versions.last }

    before do
      allow(work).to receive(:latest_published_version)
        .and_return(v2)
    end

    it 'renders the current version as the dropdown toggle button' do
      expect(result.css('.btn.dropdown-toggle').text)
        .to include('V2')
        .and include('published')
    end

    it 'renders the current version as a disabled menu item' do
      expect(result.css('.dropdown-item.disabled').length).to eq 1
      expect(result.css('.dropdown-item.disabled').text).to include('V2')
    end

    it 'links the latest published version to the *Work* resource page' do
      expect(result.at_css('.dropdown-item:contains("V2")')[:href])
        .to eq resource_path(work.uuid)
    end

    it 'links all other versions to their WorkVersion resource page' do
      expect(result.at_css('.dropdown-item:contains("V1")')[:href])
        .to eq resource_path(v1.uuid)
    end
  end

  context 'when the work has only a draft' do
    let(:work) { WorkDecorator.new(build(:work, has_draft: true)) }
    let(:current_version) { work.decorated_versions.first }

    before do
      allow(work).to receive(:latest_published_version)
        .and_return(NullWorkVersion.new)
    end

    it 'renders the draft version as the dropdown toggle button' do
      expect(result.css('.btn.dropdown-toggle').text)
        .to include('V1')
        .and include('draft')
    end
  end

  context 'when the work has a published and draft versions' do
    let(:work) { WorkDecorator.new(build(:work, versions_count: 2, has_draft: true)) }
    let(:draft_version) { work.decorated_versions.last }
    let(:published_version) { work.decorated_versions.first }

    let(:navigable_policy) { instance_spy 'WorkVersionPolicy', navigable?: true }
    let(:unnavigable_policy) { instance_spy 'WorkVersionPolicy', navigable?: false }

    context 'when the draft version is navigable' do
      let(:current_version) { published_version }

      before do
        allow(mock_helpers).to receive(:policy).and_return(navigable_policy)
      end

      it 'includes the draft and published version in the dropdown menu' do
        expect(result.css('.dropdown-item').text)
          .to include('V1')
          .and include('V2')
      end
    end

    context 'when the draft version is not navigable' do
      before do
        allow(mock_helpers).to receive(:policy).with(draft_version)
          .and_return(unnavigable_policy)

        allow(mock_helpers).to receive(:policy).with(published_version)
          .and_return(navigable_policy)
      end

      context 'when the current version is the published one' do
        let(:current_version) { published_version }

        it 'does NOT include the draft version in the dropdown menu' do
          expect(result.css('.dropdown-item').text)
            .to include('V1')

          expect(result.css('.dropdown-item').text)
            .not_to include('V2')
        end
      end

      context 'when the current version is the draft one' do
        let(:current_version) { draft_version }

        it 'DOES include the draft version in the dropdown menu' do
          expect(result.css('.dropdown-item').text)
            .to include('V1')
            .and include('V2')
        end
      end
    end
  end
end
