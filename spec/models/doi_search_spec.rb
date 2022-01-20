# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DoiSearch do
  let!(:work_version_1) { create :work_version, doi: '10.26207/rb4s-33xs' }
  let!(:work) { create :work, doi: '10.18113/dmnf-6dzs' }
  let!(:collection_1) { create :collection, doi: '10.18113/dmnf-6dzs', identifier: ['doi:10.26207/upw2-pkx3'] }
  let!(:collection_2) { create :collection, doi: '10.18113/qi03-b693' }

  before do
    Work.reindex_all(async: false)
    Collection.reindex_all
  end

  describe '.all' do
    it 'returns all unique DOIs in the index (Works and Collections but not WorkVersions)' do
      expect(described_class.all).to match(
        {
          'doi:10.26207/upw2-pkx3' => [collection_1.uuid],
          'doi:10.18113/dmnf-6dzs' => a_collection_containing_exactly(work.uuid, collection_1.uuid),
          'doi:10.18113/qi03-b693' => [collection_2.uuid]
        }
      )
    end
  end

  describe '#results' do
    it 'returns an array of resource uuids who reference the given doi' do
      # Find a collection
      expect(described_class.new(doi: collection_2.doi).results)
        .to contain_exactly(collection_2.uuid)

      # Cannot find a work version
      expect(described_class.new(doi: work_version_1.doi).results)
        .to eq []

      # Find a collection, with non-canonical formatting
      expect(described_class.new(doi: 'https://doi.org/10.18113/qi03-b693').results)
        .to contain_exactly(collection_2.uuid)

      # Find the work and collection combo
      expect(described_class.new(doi: collection_1.doi).results)
          .to contain_exactly(work.uuid, collection_1.uuid)

      # Find nothing
      expect(described_class.new(doi: 'nothing to see here').results)
        .to eq []

      # Find l337 h4x
      expect(described_class.new(doi: '"} hacking in progress').results)
        .to eq []
    end
  end
end
