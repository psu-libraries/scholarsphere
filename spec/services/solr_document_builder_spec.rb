# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDocumentBuilder do
  subject(:document) { builder.generate(resource: resource) }

  let(:builder) { described_class.new(DefaultSchema) }

  describe '#generate' do
    context 'with a WorkVersion' do
      let(:resource) { build(:work_version) }

      it 'returns a hash' do
        allow(resource).to receive(:thumbnail_url).and_return 'url.com/path/file'
        expect(document).to include(
          title_tesim: [resource.title],
          model_ssi: 'WorkVersion',
          id: resource.uuid,
          thumbnail_url_ssi: 'url.com/path/file'
        )
      end
    end

    context 'when the resource has no uuid' do
      let(:resource) { Struct.new('UnsupportedResource').new }

      it 'raises an error' do
        expect { document }.to raise_error(SolrDocumentBuilder::Error)
      end
    end

    context 'when the schema has fields to reject' do
      let(:resource) { build(:work_version) }

      before { allow_any_instance_of(DefaultSchema).to receive(:reject).and_return([:title_tesim]) }

      it 'removes the rejected fields' do
        expect(document.keys).not_to include(:title_tesim)
      end
    end
  end
end
