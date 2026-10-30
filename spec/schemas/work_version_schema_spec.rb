# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersionSchema, type: :schema do
  let(:schema) { described_class.new(resource: resource) }

  describe '#document' do
    context 'when the work is successfully published' do
      let(:resource) { create(:work, has_draft: false).versions.first }

      it { expect(errors).to be_empty }
    end
  end
end
