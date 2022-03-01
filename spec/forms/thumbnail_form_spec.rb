# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThumbnailForm, type: :model do
  subject(:form) { described_class.new(resource: work, params: params) }

  let(:work) { create(:work, versions_count: 2, has_draft: true) }

  describe '#save' do
    describe "when thumbnail_selection is #{ThumbnailSelections::UPLOADED_IMAGE}" do
      before do
        work.update thumbnail_selection: ThumbnailSelections::UPLOADED_IMAGE
      end

      context 'when a thumbnail_upload already exists' do
        let(:params) do
          { thumbnail_upload:
                FileHelpers.shrine_upload(file: Pathname.new(fixture_path).join('image.png')).to_json }
        end

        let!(:thumbnail_upload) { create :thumbnail_upload, resource: work }

        it 'deletes existing thumbnail_upload and file_resource and uploads the new one' do
          form.save
          expect { thumbnail_upload.reload }.to raise_error ActiveRecord::RecordNotFound
          expect(work.reload.thumbnail_upload).to be_present
          expect(work.reload.thumbnail_upload.file_resource.file_data['metadata']['filename']).to eq 'image.png'
        end
      end

      context 'when a thumbnail_upload does not already exist' do
        let(:params) do
          { thumbnail_upload:
                FileHelpers.shrine_upload(file: Pathname.new(fixture_path).join('image.png')).to_json }
        end

        it 'creates a thumbnail_upload and file_resource' do
          form.save
          expect(work.reload.thumbnail_upload).to be_present
          expect(work.reload.thumbnail_upload.file_resource.file_data['metadata']['filename']).to eq 'image.png'
        end
      end
    end

    describe "when thumbnail selection is not #{ThumbnailSelections::UPLOADED_IMAGE}" do
      it 'updates thumbnail_selection' do
      end
    end
  end
end
