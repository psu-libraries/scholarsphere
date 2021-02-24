# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LatestPublishedVersionSchema do
  subject { described_class.new(resource: resource) }

  describe '#document' do
    context 'with creators' do
      let(:resource) { create(:work, has_draft: false) }

      its(:document) do
        is_expected.to include(
          creators_sim: resource.latest_published_version.creators.map(&:display_name),
          creators_tesim: resource.latest_published_version.creators.map(&:display_name)
        )
      end
    end

    context 'with keyword and subject facets' do
      let(:resource) { create(:work, has_draft: false) }

      its(:document) do
        is_expected.to include(
          keyword_sim: resource.latest_published_version.keyword,
          subject_sim: resource.latest_published_version.subject
        )
      end
    end

    context 'with an indexed published date' do
      let(:resource) { create(:work, has_draft: false) }

      its(:document) do
        is_expected.to include(
          published_date_dtrsi: kind_of(String)
        )
      end
    end

    context 'when the resource does not have a published version' do
      let(:resource) { create(:work, has_draft: true) }

      its(:document) { is_expected.to be_empty }
    end

    context 'when the resource does not respond to :latest_published_version' do
      let(:resource) { Struct.new('UnsupportedResource').new }

      its(:document) { is_expected.to be_empty }
    end

    context 'when the resource is a NullWorkVersion' do
      let(:resource) { NullWorkVersion.new }

      its(:document) { is_expected.to be_empty }
    end
  end
end
