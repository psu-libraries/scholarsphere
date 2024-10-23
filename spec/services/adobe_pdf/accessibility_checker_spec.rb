# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdobePdf::AccessibilityChecker, :vcr do
  let(:checker) { described_class.new(resource) }

  describe '#initialize' do
    context 'when the file size exceeds the limit' do
      let(:resource) { double('FileRespurce', file_data: { 'metadata' => { 'size' => file_size } }) }
      let(:file_size) { 150_000_000 }

      it 'raises a FileSizeExceededError' do
        expect { checker }.to raise_error(AdobePdf::AccessibilityChecker::FileSizeExceededError, 'File size exceeds the limit of 100Mb')
      end
    end

    context 'when the file size does not exceed the limit' do
      let(:resource) { double('FileRespurce', file_data: { 'metadata' => { 'size' => file_size } }) }
      let(:file_size) { 50_000_000 }

      it 'does not raise an error' do
        expect { checker }.not_to raise_error
      end
    end
  end

  describe '#call' do
    let(:resource) { create(:file_resource, :pdf) }

    describe "happy path" do
      it "fetches the accessibility report" do
        expect { checker.call }.to change { AccessibilityCheckResult.count }.by(1)
      end
    end
  end
end
