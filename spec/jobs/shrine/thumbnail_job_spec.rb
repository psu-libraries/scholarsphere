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

    it 'reindexes associated work versions when no thumbnail upload is present' do
      work_version_one = instance_spy(WorkVersion)
      work_version_two = instance_spy(WorkVersion)
      allow(pdf_record).to receive_messages(work_versions: [work_version_one, work_version_two], thumbnail_upload: nil)

      described_class.perform_now(pdf_record)

      expect(work_version_one).to have_received(:update_index)
      expect(work_version_two).to have_received(:update_index)
    end

    it 'reindexes associated thumbnail upload resource when present' do
      thumbnail_upload = create(:thumbnail_upload)
      resource = thumbnail_upload.resource
      allow(resource).to receive(:update_index)
      allow(pdf_record).to receive_messages(work_versions: [], thumbnail_upload: thumbnail_upload)

      described_class.perform_now(pdf_record)

      expect(resource).to have_received(:update_index)
    end
  end
end
