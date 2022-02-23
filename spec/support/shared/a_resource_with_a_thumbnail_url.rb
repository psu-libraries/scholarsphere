# frozen_string_literal: true

RSpec.shared_examples 'a resource with a thumbnail url' do
  let(:mock_attacher) { instance_double FileUploader::Attacher }
  let(:mock_attacher_thumbnail_upload) { instance_double FileUploader::Attacher }

  before do
    resource.thumbnail_upload = create :thumbnail_upload
    resource.save
  end

  describe '#thumbnail_url' do
    context 'when resource #auto_generate_thumbnail? is true' do
      before do
        allow(resource).to receive(:auto_generate_thumbnail?).and_return true
      end

      context 'when auto generated thumbnail url exists' do
        before do
          allow(mock_attacher).to receive(:url).with(:thumbnail).and_return 'url.com/path/file'
          allow(mock_attacher_thumbnail_upload).to receive(:url).with(:thumbnail)
            .and_return 'url.com/path/thumbnail-upload'
        end

        it 'returns thumbnail url' do
          allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
          allow(resource.thumbnail_upload.file_resource).to receive(:file_attacher)
            .and_return(mock_attacher_thumbnail_upload)
          expect(resource.thumbnail_url).to eq 'url.com/path/file'
        end
      end

      context 'when auto generated thumbnail url does not exist' do
        before do
          allow(mock_attacher).to receive(:url).with(:thumbnail).and_return nil
          allow(mock_attacher_thumbnail_upload).to receive(:url).with(:thumbnail)
            .and_return 'url.com/path/thumbnail-upload'
        end

        it 'returns nil' do
          allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
          allow(resource.thumbnail_upload.file_resource).to receive(:file_attacher)
            .and_return(mock_attacher_thumbnail_upload)
          expect(resource.thumbnail_url).to eq nil
        end
      end
    end

    context 'when resource #auto_generate_thumbnail? is false' do
      before do
        allow(resource).to receive(:auto_generate_thumbnail?).and_return false
      end

      context 'when uploaded thumbnail url is present' do
        before do
          allow(mock_attacher).to receive(:url).with(:thumbnail).and_return 'url.com/path/file'
          allow(mock_attacher_thumbnail_upload).to receive(:url).with(:thumbnail)
            .and_return 'url.com/path/thumbnail-upload'
        end

        it 'returns thumbnail url' do
          allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
          allow(resource.thumbnail_upload.file_resource).to receive(:file_attacher)
            .and_return(mock_attacher_thumbnail_upload)
          expect(resource.thumbnail_url).to eq 'url.com/path/thumbnail-upload'
        end
      end

      context 'when uploaded thumbnail url is not present' do
        before do
          allow(mock_attacher).to receive(:url).with(:thumbnail).and_return 'url.com/path/file'
          allow(mock_attacher_thumbnail_upload).to receive(:url).with(:thumbnail).and_return nil
        end

        it 'returns nil' do
          allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
          allow(resource.thumbnail_upload.file_resource).to receive(:file_attacher)
            .and_return(mock_attacher_thumbnail_upload)
          expect(resource.thumbnail_url).to eq nil
        end
      end
    end
  end

  describe '#auto_generated_thumbnail_url' do
    context 'when thumbnails exists from submitted file resources' do
      before do
        allow(mock_attacher).to receive(:url).with(:thumbnail).and_return 'url.com/path/file'
      end

      it 'returns a url' do
        allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
        expect(resource.auto_generated_thumbnail_url).to eq 'url.com/path/file'
      end
    end

    context 'when no thumbnail exists from submitted file resources' do
      before do
        allow(mock_attacher).to receive(:url).with(:thumbnail).and_return nil
      end

      it 'returns nil' do
        allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
        expect(resource.auto_generated_thumbnail_url).to eq nil
      end
    end
  end

  describe '#thumbnail_present?' do
    context 'when an uploaded thumbnail url is found and an auto generated thumbnail url is not' do
      before do
        allow(mock_attacher).to receive(:url).with(:thumbnail).and_return nil
        allow(mock_attacher_thumbnail_upload).to receive(:url).with(:thumbnail).and_return 'url.com/path/file'
      end

      it 'returns true' do
        allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
        allow(resource.thumbnail_upload.file_resource).to receive(:file_attacher)
          .and_return(mock_attacher_thumbnail_upload)
        expect(resource.thumbnail_present?).to eq true
      end
    end

    context 'when an auto generated thumbnail url is found and an uploaded thumbnail url is not' do
      before do
        allow(mock_attacher).to receive(:url).with(:thumbnail).and_return 'url.com/path/file'
        allow(mock_attacher_thumbnail_upload).to receive(:url).with(:thumbnail).and_return nil
      end

      it 'returns true' do
        allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
        allow(resource.thumbnail_upload.file_resource).to receive(:file_attacher)
          .and_return(mock_attacher_thumbnail_upload)
        expect(resource.thumbnail_present?).to eq true
      end
    end

    context 'when both an auto generated thumbnail url and an uploaded thumbnail url are found' do
      before do
        allow(mock_attacher).to receive(:url).with(:thumbnail).and_return 'url.com/path/file'
        allow(mock_attacher_thumbnail_upload).to receive(:url).with(:thumbnail).and_return 'url.com/path/file'
      end

      it 'returns true' do
        allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
        allow(resource.thumbnail_upload.file_resource).to receive(:file_attacher)
          .and_return(mock_attacher_thumbnail_upload)
        expect(resource.thumbnail_present?).to eq true
      end
    end

    context 'when neither an auto generated thumbnail url nor an uploaded thumbnail url are found' do
      before do
        allow(mock_attacher).to receive(:url).with(:thumbnail).and_return nil
        allow(mock_attacher_thumbnail_upload).to receive(:url).with(:thumbnail).and_return nil
      end

      it 'returns false' do
        allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
        allow(resource.thumbnail_upload.file_resource).to receive(:file_attacher)
          .and_return(mock_attacher_thumbnail_upload)
        expect(resource.thumbnail_present?).to eq false
      end
    end
  end
end
