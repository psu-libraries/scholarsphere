# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IndexingService, type: :service do
  let(:resource) { build(:work_version) }

  describe '.call' do
    subject(:service) { described_class.call(resource: resource, schema: {}) }

    context 'with a supported resource' do
      let(:resource) { instance_spy('IndexedResource', uuid: SecureRandom.uuid, class: 'IndexedResource') }

      it 'indexes a minimal amount of metadata in Solr' do
        service
        document = SolrDocument.find(resource.uuid)
        expect(document.id).to eq(resource.uuid)
        expect(document['model_ssi']).to eq('IndexedResource')
      end
    end

    context 'with an improperly identified resource' do
      let(:resource) { Struct.new('UnsupportedResource') }

      it 'raises an error' do
        expect { service }.to raise_error(IndexingService::Error, 'Class has no uuid defined')
      end
    end
  end

  describe '#document' do
    subject { described_class.new(resource, schema) }

    context 'with a simple schema' do
      let(:schema) { { title_tesim: ['title'], foo_text: ['title', 'description'] } }

      its(:document) do
        is_expected.to eq(
          'title_tesim' => [resource.title],
          'foo_text' => [resource.title, resource.description]
        )
      end
    end

    context 'when the schema contains undefined attributes' do
      let(:schema) { { title_tesim: ['title', 'bad_attribute'] } }

      its(:document) { is_expected.to eq('title_tesim' => [resource.title, nil]) }
    end
  end
end
