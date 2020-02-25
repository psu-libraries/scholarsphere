# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDocumentBuilder do
  subject(:document) { builder.generate(resource: resource) }

  let(:builder) { described_class.new(DefaultSchema) }

  describe '#generate' do
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

    context 'when the resource has no uuid' do
      let(:resource) { Struct.new('UnsupportedResource').new }

      it 'raises an error' do
        expect { document }.to raise_error(SolrDocumentBuilder::Error)
      end
    end
  end
end
