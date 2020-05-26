# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BaseSchema do
  subject(:schema) { described_class.new(resource: 'resource') }

  it { is_expected.to respond_to(:resource) }

  context 'when implemented without a subclass' do
    specify do
      expect { schema.document }.to raise_error(ArgumentError, 'Inheriting class must implement #document')
    end
  end

  describe '#reject' do
    its(:reject) { is_expected.to be_empty }
  end
end
