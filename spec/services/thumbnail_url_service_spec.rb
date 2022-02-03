# frozen_string_literal: true

require 'rails_helper'

describe ThumbnailUrlService do
  let(:service) { described_class.new(resource) }
  let(:mock_attacher) { instance_double FileUploader::Attacher }

  before do
    allow(mock_attacher).to receive(:url).with(:thumbnail).and_return 'url.com/path/file'
  end

  describe '#url' do
    context 'when resource is a SolrDocument' do
      context 'when SolrDocument encapsulates a Collection' do
        let!(:collection) { create :collection }
        let(:resource) { SolrDocument.new(collection.to_solr) }

        before do
          create :work, versions_count: 2, collections: [collection]
        end

        it 'return thumbnail url' do
          allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
          expect(service.url).to eq 'url.com/path/file'
        end
      end

      context 'when SolrDocument encapsulates a Work' do
        let!(:work) { create :work, versions_count: 2 }
        let(:resource) { SolrDocument.new(work.to_solr) }

        it 'return thumbnail url' do
          allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
          expect(service.url).to eq 'url.com/path/file'
        end
      end
    end

    context 'when resource is a WorkVersion' do
      let!(:work) { create :work }
      let!(:work_version) { create :work_version, :with_files, work: work }
      let(:resource) { work_version }

      it 'return thumbnail url' do
        allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
        expect(service.url).to eq 'url.com/path/file'
      end
    end

    context 'when resource is a Work' do
      let!(:work) { create :work, versions_count: 2 }
      let(:resource) { work }

      it 'return thumbnail url' do
        allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
        expect(service.url).to eq 'url.com/path/file'
      end
    end

    context 'when resource is a Collection' do
      let!(:collection) { create :collection }
      let(:resource) { collection }

      before do
        create :work, versions_count: 2, collections: [collection]
      end

      it 'return thumbnail url' do
        allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
        expect(service.url).to eq 'url.com/path/file'
      end
    end
  end

  context 'when resource has no files' do
    let!(:work) { create :work }
    let!(:work_version) { create :work_version, work: work }
    let(:resource) { work_version }

    it 'returns nil' do
      allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
      expect(mock_attacher).not_to have_received(:url).with(:thumbnail)
      expect(service.url).to eq nil
    end
  end

  context 'when resource file has no thumbnail' do
    let(:mock_attacher) { instance_double FileUploader::Attacher }
    let!(:work) { create :work }
    let!(:work_version) { create :work_version, :with_files, work: work }
    let(:resource) { work_version }

    it 'returns nil' do
      allow(mock_attacher).to receive(:url).with(:thumbnail).and_return nil
      allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
      expect(service.url).to eq nil
    end
  end
end
