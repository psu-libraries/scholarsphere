# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shrine::ThumbnailJob, skip: !ci_build? do
  let(:pdf_record) { build(:file_resource, :pdf) }
  let(:doc_record) { build(:file_resource, :doc) }
  let(:image_record) { build(:file_resource, :with_processed_image) }

  context 'with valid input' do
    it 'creates thumbnails from pdf' do
      described_class.perform_now(pdf_record)
      expect(pdf_record.file_attacher.url(:thumbnail)).to include('thumbnails')
    end

    it 'does create thumbnails from docx' do
      described_class.perform_now(doc_record)
      expect(doc_record.file_attacher.url(:thumbnail)).to include('thumbnails')
    end

    it 'does create a thumbnail from an image' do
      described_class.perform_now(image_record)
      expect(image_record.file_attacher.url(:thumbnail)).to include('thumbnails')
    end
  end
end
