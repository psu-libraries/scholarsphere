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
      let(:extracted_text) { Faker::String.random }

      its(:document) { is_expected.to eq({ extracted_text_tei: extracted_text }) }
    end
  end
end
