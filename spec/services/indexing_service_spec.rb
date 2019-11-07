# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IndexingService, type: :service do
  let(:resource) { build(:work_version) }

  describe '.call' do
    subject(:service) { described_class.call(resource: resource, schema: {}) }

    context 'with a supported resource' do
      let(:resource) { instance_spy('IndexedResource', uuid: SecureRandom.uuid, class: 'IndexedResource') }

      it 'indexes a minimal amount of metadata in Solr but does not automatically commit the results' do
        service
        expect(Blacklight.default_index.connection.get('select', q: '*:*')['response']['docs'])
          .to be_empty
        document = SolrDocument.find(resource.uuid)
        expect(document.id).to eq(resource.uuid)
        expect(document['model_ssi']).to eq('IndexedResource')
      end
    end

    context 'with an improperly identified resource' do
      let(:resource) { Struct.new('UnsupportedResource').new }

      it 'raises an error' do
        expect { service }.to raise_error(IndexingService::Error, 'Struct::UnsupportedResource has no uuid defined')
      end
    end

    context 'when commit is set to true' do
      subject(:service) { described_class.call(resource: resource, schema: {}, commit: true) }

      let(:resource) { instance_spy('CommittedResource', uuid: SecureRandom.uuid, class: 'CommittedResource') }

      it 'commits the changes to the index immediately' do
        service
        expect(Blacklight.default_index.connection.get('select', q: '*:*')['response']['docs'].first['id'])
          .to eq(resource.uuid)
        document = SolrDocument.find(resource.uuid)
        expect(document.id).to eq(resource.uuid)
        expect(document['model_ssi']).to eq('CommittedResource')
      end
    end

    context 'when no schema is specified' do
      subject(:service) { described_class.call(resource: resource) }

      let(:resource) { instance_spy('SchemalessResource', uuid: SecureRandom.uuid, class: 'SchemalessResource') }

      it 'uses the default schema on the resource' do
        service
        document = SolrDocument.find(resource.uuid)
        expect(document.id).to eq(resource.uuid)
        expect(document['model_ssi']).to eq('SchemalessResource')
      end
    end
  end

  describe '#document' do
    subject { described_class.new(resource, schema, false) }

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
