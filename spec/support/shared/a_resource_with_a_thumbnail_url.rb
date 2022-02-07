# frozen_string_literal: true

RSpec.shared_examples 'a resource with a thumbnail url' do
  let(:mock_attacher) { instance_double FileUploader::Attacher }

  context 'when thumbnail url exists' do
    before do
      allow(mock_attacher).to receive(:url).with(:thumbnail).and_return 'url.com/path/file'
    end

    it 'returns thumbnail url' do
      allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
      expect(resource.thumbnail_url).to eq 'url.com/path/file'
    end
  end

  context 'when thumbnail url does not exist' do
    before do
      allow(mock_attacher).to receive(:url).with(:thumbnail).and_return nil
    end

    it 'returns nil' do
      allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
      expect(resource.thumbnail_url).to eq nil
    end
  end
end
