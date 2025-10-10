# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BuildAutoRemediatedWorkVersionJob do
  let(:file_resource) { create(:file_resource) }
  let(:remediated_file_url) { 'https://example.com/remediated.pdf' }

  describe '#perform' do
    before do
      allow(BuildAutoRemediatedWorkVersion).to receive(:call)
    end

    it 'calls the service when perform_now is used' do
      described_class.perform_now(file_resource.id, remediated_file_url)

      expect(BuildAutoRemediatedWorkVersion).to have_received(:call).with(file_resource, remediated_file_url)
    end
  end
end
