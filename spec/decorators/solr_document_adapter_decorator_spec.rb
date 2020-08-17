# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDocumentAdapterDecorator do
  subject(:decorator) { described_class.new(resource) }

  let(:resource) { instance_spy 'WorkVersion', id: 123, uuid: '123-abc' }

  its(:itemtype) { is_expected.to eq 'http://schema.org/Thing' }

  describe '#id' do
    it 'returns the uuid' do
      expect(decorator.id).to eq resource.uuid
    end
  end
end
