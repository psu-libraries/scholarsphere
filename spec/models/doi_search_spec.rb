# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DoiSearch do
  let!(:work_version_1) { create :work_version, doi: 'doi:10.26207/upw2-pkx3' }
  let!(:work_version_2) { create :work_version, doi: 'doi:10.18113/dmnf-6dzs', identifier: ['doi:10.26207/upw2-pkx3'] }
  let!(:collection) { create :collection, doi: 'doi:10.18113/qi03-b693' }

  before do
    Work.reindex_all(async: false)
    Collection.reindex_all
  end

  describe '.all' do
    it 'returns all unique DOIs in the index' do
      expect(described_class.all).to match(
        {
          'doi:10.26207/upw2-pkx3' => a_collection_containing_exactly(work_version_1.uuid, work_version_2.uuid),
          'doi:10.18113/dmnf-6dzs' => [work_version_2.uuid],
          'doi:10.18113/qi03-b693' => [collection.uuid]
        }
      )
    end
  end

  describe '#results' do
    it 'returns an array of resource uuids who reference the given doi' do
      # Find a collection
      expect(described_class.new(doi: collection.doi).results)
        .to contain_exactly(collection.uuid)

      # Find a work version
      # Note that w_v_2 duplicates w_v_1's doi in its identifier attribute
      expect(described_class.new(doi: work_version_1.doi).results)
        .to contain_exactly(work_version_1.uuid, work_version_2.uuid)

      expect(described_class.new(doi: work_version_2.doi).results)
        .to contain_exactly(work_version_2.uuid)

      # Find a collection, with non-canonical formatting
      expect(described_class.new(doi: 'https://doi.org/10.18113/qi03-b693').results)
        .to contain_exactly(collection.uuid)

      # Find nothing
      expect(described_class.new(doi: 'nothing to see here').results)
        .to eq []

      # Find l337 h4x
      expect(described_class.new(doi: '"} hacking in progress').results)
        .to eq []
    end
  end
end
