# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDocumentBuilder do
  subject(:document) { described_class.call(resource: resource) }

  describe '::call' do
    context 'with a WorkVersion' do
      let(:resource) { build(:work_version) }

      it 'returns a hash' do
        expect(document).to include(
          title_tesim: [resource.title],
          model_ssi: 'WorkVersion',
          id: resource.uuid
        )
      end
    end

    context 'with a custom schema' do
      subject(:document) { described_class.call(resource: resource, schema: schema) }

      let(:resource) { build(:work_version) }
      let(:schema) { { title_ssim: ['title'] } }

      it 'returns a hash using the schema' do
        expect(document).to include(
          title_ssim: [resource.title],
          model_ssi: 'WorkVersion',
          id: resource.uuid
        )
      end
    end

    context 'when the resource has no uuid' do
      let(:resource) { Struct.new('UnsupportedResource').new }

      it 'raises an error' do
        expect { described_class.call(resource: resource) }.to raise_error(SolrDocumentBuilder::Error)
      end
    end

    context 'when the resource is nil' do
      it 'returns an empty hash' do
        expect(described_class.call(resource: nil)).to be_empty
      end
    end
  end
end
