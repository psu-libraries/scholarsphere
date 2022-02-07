# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolrDocument, type: :model do
  subject { described_class.new(document) }

  context 'when document contains a collection' do
    it_behaves_like 'a resource with a thumbnail url' do
      let!(:collection) { create :collection }
      let(:document) { collection.to_solr }
      let(:resource) { subject }

      before do
        create :work, versions_count: 2, collections: [collection]
      end
    end
  end

  context 'when document contains a work' do
    it_behaves_like 'a resource with a thumbnail url' do
      let!(:work) { create :work, versions_count: 2 }
      let(:document) { work.to_solr }
      let(:resource) { subject }
    end
  end

  describe '#deposited_at' do
    context 'when the value exists' do
      let(:document) { { deposited_at_dtsi: '2020-11-10T02:05:05Z' } }

      its(:deposited_at) { is_expected.to be_a(Time) }
    end

    context 'when the value is nil' do
      let(:document) { {} }

      its(:deposited_at) { is_expected.to be_nil }
    end
  end
end
