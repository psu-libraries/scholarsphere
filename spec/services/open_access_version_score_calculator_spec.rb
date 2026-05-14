# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenAccessVersionScoreCalculator do
  # These tests use PDF file fixtures containing patterns/signals that indicate either
  # accepted or published versions.  The fixtures are crafted to test all the
  # permutations of logic in the OpenAccessVersionScoreCalculator class.

  subject(:calculator) do
    described_class.new(
      work_version: work_version,
      pdf_reader: pdf_reader,
      filename: filename
    )
  end

  let(:work_version) do
    instance_double(
      WorkVersion,
      published_date: Date.new(2000, 1, 1),
      identifier: 'https://doi.org/10.1234/1234',
      publisher: "Jerry's Publishing Company"
    )
  end
  let(:pdf_reader) { instance_double(PDF::Reader, pages: pages) }
  let(:pages) { [page] }
  let(:page) { instance_double(PDF::Reader::Page, text: 'sample text body') }
  let(:fixture_pdf_path) { Rails.root.join('spec/fixtures/pdf_check_published_versionS123456abc.pdf') }
  # Derive filename from fixture files
  let(:filename) { fixture_pdf_path.basename.to_s }

  describe '#score' do
    context 'when parsing real PDF fixtures' do
      context 'when pdf indicates published version' do
        # The filename contains a published version signal
        let(:fixture_pdf_path) { Rails.root.join('spec/fixtures/open_access_version_guesser/pdf_check_published_versionS123456abc.pdf') }
        let(:pdf_reader) do
          PDF::Reader.new(fixture_pdf_path.to_s)
        end

        it 'returns a positive score' do
          expect(calculator.score).to eq(4)
        end
      end

      context 'when pdf indicates accepted version' do
        # The filename contains an accepted version signal
        let(:fixture_pdf_path) { Rails.root.join('spec/fixtures/open_access_version_guesser/pdf_check_accepted_version_postprint.pdf') }
        let(:pdf_reader) do
          PDF::Reader.new(fixture_pdf_path.to_s)
        end

        it 'returns a negative score' do
          expect(calculator.score).to eq(-3)
        end
      end

      context 'when pdf indicates unknown version' do
        let(:fixture_pdf_path) { Rails.root.join('spec/fixtures/open_access_version_guesser/pdf_check_unknown_version.pdf') }
        let(:pdf_reader) do
          PDF::Reader.new(fixture_pdf_path.to_s)
        end

        it 'returns 0' do
          expect(calculator.score).to eq(0)
        end
      end
    end

    context 'when pdf_reader is nil' do
      let(:pdf_reader) { nil }

      it 'returns zero' do
        expect(calculator.score).to eq(0)
      end
    end

    context 'when extracted content is empty' do
      before do
        allow(page).to receive(:text).and_raise(StandardError)
      end

      it 'returns zero' do
        expect(calculator.score).to eq(0)
      end
    end

    context 'when rules file does not exist' do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it 'raises a clear error' do
        expect { calculator.score }
          .to raise_error(RuntimeError, 'Error: config/open_access_version_guessing_rules.csv does not exist or cannot be read.')
      end
    end

    context 'when parser raises a PDF::Reader error while extracting content' do
      it 'returns zero' do
        allow(pages).to receive(:each).and_raise(PDF::Reader::MalformedPDFError)
        expect(calculator.score).to eq(0)
      end
    end

    context 'when one page fails but another page succeeds' do
      let(:first_page) { instance_double(PDF::Reader::Page) }
      let(:second_page) { instance_double(PDF::Reader::Page, text: 'found phrase') }
      let(:pages) { [first_page, second_page] }

      before do
        allow(first_page).to receive(:text).and_raise(StandardError)
      end

      it 'continues processing and scores based on remaining pages' do
        expect(calculator.score).to eq(1)
      end
    end
  end
end
