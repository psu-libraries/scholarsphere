# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenAccessVersion::Guesser do
  subject(:guesser) { described_class.new(work_version: work_version) }

  let(:work_version) { instance_double(WorkVersion, file_resources: file_resources, publisher: nil) }
  let(:file_resources) { [file_resource] }
  let(:file_resource) { instance_double(FileResource, file: attached_file, pdf?: pdf, docx?: docx) }
  let(:attached_file) { instance_double(Shrine::UploadedFile, original_filename: 'paper.pdf') }
  let(:pdf) { true }
  let(:docx) { false }
  let(:pdf_reader) { instance_double(PDF::Reader, objects: {}) }
  let(:file_download) { instance_double(Tempfile, path: '/tmp/fake-pdf-content.pdf', close!: nil) }

  before do
    allow(attached_file).to receive(:download).and_return(file_download)
    allow(PDF::Reader).to receive(:new).and_return(pdf_reader)
    exif_checker = instance_double(OpenAccessVersion::ExifChecker, version: nil)
    allow(OpenAccessVersion::ExifChecker).to receive(:new).and_return(exif_checker)
  end

  describe '#version' do
    context 'when Exif check returns a version' do
      let(:exif_version) { OpenAccessVersion::VersionValues::PUBLISHED }

      before do
        exif_checker = instance_double(OpenAccessVersion::ExifChecker, version: exif_version)
        allow(OpenAccessVersion::ExifChecker).to receive(:new).and_return(exif_checker)
      end

      it 'returns the EXIF version' do
        expect(guesser.version).to eq(exif_version)
      end
    end

    context 'when EXIF check returns nil and no arXiv watermark is found' do
      context 'when score is positive' do
        before do
          calculator = instance_double(OpenAccessVersion::ScoreCalculator, score: 2)
          allow(OpenAccessVersion::ScoreCalculator).to receive(:new).and_return(calculator)
        end

        it 'returns published version' do
          expect(guesser.version).to eq(OpenAccessVersion::VersionValues::PUBLISHED)
        end
      end

      context 'when score is negative' do
        before do
          calculator = instance_double(OpenAccessVersion::ScoreCalculator, score: -1)
          allow(OpenAccessVersion::ScoreCalculator).to receive(:new).and_return(calculator)
        end

        it 'returns accepted version' do
          expect(guesser.version).to eq(OpenAccessVersion::VersionValues::ACCEPTED)
        end
      end

      context 'when score is zero' do
        before do
          calculator = instance_double(OpenAccessVersion::ScoreCalculator, score: 0)
          allow(OpenAccessVersion::ScoreCalculator).to receive(:new).and_return(calculator)
        end

        it 'returns UNKNOWN' do
          expect(guesser.version).to eq(OpenAccessVersion::VersionValues::UNKNOWN)
        end
      end

      context 'when multiple PDFs contribute score' do
        let(:file_resources) { [file_resource, second_file_resource] }
        let(:second_file_resource) { instance_double(FileResource, file: second_attached_file, pdf?: true, docx?: false) }
        let(:second_attached_file) { instance_double(Shrine::UploadedFile, original_filename: 'paper-2.pdf') }
        let(:second_file_download) { instance_double(Tempfile, path: '/tmp/fake-pdf-content-2.pdf', close!: nil) }

        before do
          allow(second_attached_file).to receive(:download).and_return(second_file_download)
          first_calculator = instance_double(OpenAccessVersion::ScoreCalculator, score: 2)
          second_calculator = instance_double(OpenAccessVersion::ScoreCalculator, score: -3)
          allow(OpenAccessVersion::ScoreCalculator).to receive(:new).and_return(first_calculator, second_calculator)
        end

        it 'accumulates score across files' do
          expect(guesser.version).to eq(OpenAccessVersion::VersionValues::ACCEPTED)
        end
      end
    end

    context 'when EXIF check returns nil' do
      context 'when the PDF contains an arXiv watermark' do
        let(:fixture_pdf_path) { Rails.root.join('spec/fixtures/open_access_version/arxiv_artifact_only.pdf') }
        let(:file_download) { instance_double(Tempfile, path: fixture_pdf_path.to_s, close!: nil) }
        let(:pdf_reader) do
          PDF::Reader.new(file_download.path)
        end

        before do
          allow(OpenAccessVersion::ScoreCalculator).to receive(:new)
        end

        it 'returns accepted version without using the score calculator' do
          expect(guesser.version).to eq(OpenAccessVersion::VersionValues::ACCEPTED)
          expect(OpenAccessVersion::ScoreCalculator).not_to have_received(:new)
        end
      end

      context 'when the file is not a PDF' do
        let(:pdf) { false }
        let(:docx) { true }

        before do
          allow(OpenAccessVersion::ScoreCalculator).to receive(:new)
        end

        it 'skips arXiv check and score calculation for that file to return UNKNOWN' do
          expect(guesser.version).to eq OpenAccessVersion::VersionValues::UNKNOWN
          expect(OpenAccessVersion::ScoreCalculator).not_to have_received(:new)
        end
      end

      context 'when PDF::Reader raises a malformed PDF error' do
        before do
          allow(PDF::Reader).to receive(:new).and_raise(PDF::Reader::MalformedPDFError)
          calculator = instance_double(OpenAccessVersion::ScoreCalculator, score: 0)
          allow(OpenAccessVersion::ScoreCalculator).to receive(:new).and_return(calculator)
        end

        it 'returns UNKNOWN when no positive or negative score is found' do
          expect(guesser.version).to eq OpenAccessVersion::VersionValues::UNKNOWN
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
end
