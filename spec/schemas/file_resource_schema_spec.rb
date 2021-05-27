# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileResourceSchema do
  subject { described_class.new(resource: resource) }

  let(:resource) { instance_spy('FileResource', extracted_text: extracted_text) }

  describe '#document' do
    let(:extracted_text) { nil }

    context 'when there is no extracted text' do
      its(:document) { is_expected.to be_empty }
    end

    context 'when there is an extracted text file' do
      let(:extracted_text_file) { text_file }

      let(:extracted_text) do
        Shrine.upload(extracted_text_file.open, :store, metadata: false)
      end

      its(:document) { is_expected.to eq({ extracted_text_tei: extracted_text_file.read }) }
    end
  end
end
