# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileResourceSchema do
  subject { described_class.new(resource: resource) }

  let(:resource) { instance_spy('FileResource', extracted_text: extracted_text, file: file_metadata) }
  let(:file_metadata) { OpenStruct.new(mime_type: mime_type, size: size, original_filename: filename) }
  let(:mime_type) { Faker::File.mime_type }
  let(:size) { Faker::Number.number }
  let(:filename) { Faker::File.file_name }
  let(:extracted_text) { Faker::String.random }

  describe '#document' do
    its(:document) do
      is_expected.to include(
        extracted_text_tei: extracted_text,
        mime_type_ssi: mime_type,
        size_isi: size,
        original_filename_ssi: filename
      )
    end

    context 'when there is no extracted text' do
      let(:extracted_text) { nil }

      its(:document) { is_expected.not_to include(extracted_text_tei: '') }
    end
  end
end
