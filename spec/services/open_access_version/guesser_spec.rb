# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenAccessVersion::Guesser do
  subject(:guesser) { described_class.new(work_version: work_version) }

  let(:work_version) { instance_double(WorkVersion, file_resources: file_resources) }
  let(:file_resources) { [file_resource] }
  let(:file_resource) { instance_double(FileResource, file: attached_file) }
  let(:attached_file) { instance_double(Shrine::UploadedFile, mime_type: mime_type, original_filename: 'paper.pdf') }
  let(:mime_type) { FileResource::PDF_MIME_TYPE }
  let(:pdf_reader) { instance_double(PDF::Reader, objects: {}) }

  before do
    allow(attached_file).to receive(:open).and_yield(StringIO.new('fake-pdf-content'))
    allow(PDF::Reader).to receive(:new).and_return(pdf_reader)
  end

  describe '#version' do
    context 'when score is positive' do
      before do
        calculator = instance_double(OpenAccessVersion::ScoreCalculator, score: 2)
        allow(OpenAccessVersion::ScoreCalculator).to receive(:new).and_return(calculator)
      end

      it 'returns published version' do
        expect(guesser.version).to eq(OpenAccessVersion::Guesser::PUBLISHED_VERSION_VALUE)
      end
    end

    context 'when score is negative' do
      before do
        calculator = instance_double(OpenAccessVersion::ScoreCalculator, score: -1)
        allow(OpenAccessVersion::ScoreCalculator).to receive(:new).and_return(calculator)
      end

      it 'returns accepted version' do
        expect(guesser.version).to eq(OpenAccessVersion::Guesser::ACCEPTED_VERSION_VALUE)
      end
    end

    context 'when score is zero' do
      before do
        calculator = instance_double(OpenAccessVersion::ScoreCalculator, score: 0)
        allow(OpenAccessVersion::ScoreCalculator).to receive(:new).and_return(calculator)
      end

      it 'returns nil' do
        expect(guesser.version).to be_nil
      end
    end

    context 'when the PDF contains an arXiv watermark' do
      let(:fixture_pdf_path) { Rails.root.join('spec/fixtures/open_access_version/arxiv_artifact_only.pdf') }
      let(:pdf_reader) do
        PDF::Reader.new(fixture_pdf_path.to_s)
      end

      before do
        allow(OpenAccessVersion::ScoreCalculator).to receive(:new)
      end

      it 'returns accepted version without using the score calculator' do
        expect(guesser.version).to eq(OpenAccessVersion::Guesser::ACCEPTED_VERSION_VALUE)
        expect(OpenAccessVersion::ScoreCalculator).not_to have_received(:new)
      end
    end

    context 'when multiple PDFs contribute score' do
      let(:file_resources) { [file_resource, second_file_resource] }
      let(:second_file_resource) { instance_double(FileResource, file: second_attached_file) }
      let(:second_attached_file) { instance_double(Shrine::UploadedFile, mime_type: FileResource::PDF_MIME_TYPE, original_filename: 'paper-2.pdf') }

      before do
        allow(second_attached_file).to receive(:open).and_yield(StringIO.new('fake-pdf-content-2'))
        first_calculator = instance_double(OpenAccessVersion::ScoreCalculator, score: 2)
        second_calculator = instance_double(OpenAccessVersion::ScoreCalculator, score: -3)
        allow(OpenAccessVersion::ScoreCalculator).to receive(:new).and_return(first_calculator, second_calculator)
      end

      it 'accumulates score across files' do
        expect(guesser.version).to eq(OpenAccessVersion::Guesser::ACCEPTED_VERSION_VALUE)
      end
    end

    context 'when file is not a PDF' do
      let(:mime_type) { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }

      before do
        allow(OpenAccessVersion::ScoreCalculator).to receive(:new)
      end

      it 'skips score calculation for that file' do
        expect(guesser.version).to be_nil
        expect(OpenAccessVersion::ScoreCalculator).not_to have_received(:new)
      end
    end

    context 'when PDF::Reader raises a malformed PDF error' do
      before do
        allow(PDF::Reader).to receive(:new).and_raise(PDF::Reader::MalformedPDFError)
        calculator = instance_double(OpenAccessVersion::ScoreCalculator, score: 0)
        allow(OpenAccessVersion::ScoreCalculator).to receive(:new).and_return(calculator)
      end

      it 'returns nil when no positive or negative score is found' do
        expect(guesser.version).to be_nil
      end
    end

    context 'when PDF::Reader raises a non-PDF error' do
      before do
        allow(PDF::Reader).to receive(:new).and_raise(RuntimeError)
      end

      it 'raises the error' do
        expect { guesser.version }.to raise_error(RuntimeError)
      end
    end
  end
end
