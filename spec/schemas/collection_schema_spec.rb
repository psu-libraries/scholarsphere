# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionSchema do
  subject(:schema) { described_class.new(resource: resource) }

  describe '#document' do
    context 'when the resource is an empty collection' do
      let(:resource) { build(:collection) }

      its(:document) do
        is_expected.to eq(is_empty_bsi: true)
      end
    end

    context 'when the resource is not an empty collection' do
      let(:resource) { build(:collection) }

      before do
        resource.works = [create(:work, has_draft: false, versions_count: 1)]
      end

      its(:document) do
        is_expected.to eq(is_empty_bsi: false)
      end
    end
  end
end
