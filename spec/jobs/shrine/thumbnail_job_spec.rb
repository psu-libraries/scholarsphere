# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shrine::ThumbnailJob, type: :job, skip: ci_build? do
  let(:pdf_work_version) { create :work_version, :draft }
  let(:doc_work_version) { create :work_version, :draft }
  let(:image_work_version) { create :work_version, :draft }
  let(:pdf_record) { build(:file_resource, :pdf) }
  let(:doc_record) { build(:file_resource, :doc) }
  let(:image_record) { build(:file_resource, :with_processed_image) }

  context 'with valid input' do
    it 'creates thumbnails from pdf' do
      pdf_work_version.file_resources.append(pdf_record)
      pdf_work_version.save
      described_class.perform_now(file_resource_id: pdf_work_version.file_resources.first.id)
      file_data = pdf_work_version.file_resources.first.file_data
      expect(file_data['derivatives']).to include('thumbnail')
    end

    it 'does create thumbnails from docx' do
      doc_work_version.file_resources.append(doc_record)
      doc_work_version.save
      described_class.perform_now(file_resource_id: doc_work_version.file_resources.first.id)
      file_data = doc_work_version.file_resources.first.file_data
      expect(file_data['derivatives']).to include('thumbnail')
    end

    it 'does create a thumbnail from an image' do
      image_work_version.file_resources.append(image_record)
      image_work_version.save
      described_class.perform_now(file_resource_id: image_work_version.file_resources.first.id)
      file_data = image_work_version.file_resources.first.file_data
      expect(file_data['derivatives']).to include('thumbnail')
    end
  end
end
