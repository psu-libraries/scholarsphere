# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shrine::DestructionJob, type: :job do
  let(:mock_attacher) { instance_spy(FileUploader::Attacher) }

  before do
    allow(FileUploader::Attacher).to receive(:from_data).with('data').and_return(mock_attacher)
  end

  it 'deletes file data' do
    described_class.perform_now(data: 'data')
    expect(mock_attacher).to have_received(:destroy)
  end
end
