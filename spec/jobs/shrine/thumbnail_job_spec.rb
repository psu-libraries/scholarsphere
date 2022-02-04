# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shrine::ThumbnailJob, type: :job do
  let(:pdf_record) { build(:file_resource, :pdf) }
  let(:doc_record) { build(:file_resource, :doc) }

  context 'with valid input' do
    it 'creates thumbnails from pdf' do
      described_class.perform_now(pdf_record)
      # TODO
      # expect(Shrine::ThumbnailJob).to receive(:perform_later)
      expect(pdf_record.file_attacher.url(:thumbnail)).to include('thumbnails')
    end
  end
end
