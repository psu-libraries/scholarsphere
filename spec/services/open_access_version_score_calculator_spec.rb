# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenAccessVersionScoreCalculator do
  subject(:calculator) do
    described_class.new(
      work_version: work_version,
      pdf_reader: pdf_reader,
      filename: filename
    )
  end

  let(:filename) { 'paper.pdf' }
  let(:work_version) do
    instance_double(
      WorkVersion,
      published_date: Date.new(2020, 1, 1),
      identifier: '10.1234/example',
      publishers: ['Example Publisher']
    )
  end
  let(:pdf_reader) { instance_double(PDF::Reader, pages: pages) }
  let(:pages) { [page] }
  let(:page) { instance_double(PDF::Reader::Page, text: 'sample text body') }

  describe '#score' do
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

    context 'when rule indicates published version' do
      before do
        allow(calculator).to receive(:rules_lines).and_return([
                                                                {
                                                                  'what to search' => 'sample text',
                                                                  'where to search' => 'file',
                                                                  'how to search' => 'string',
                                                                  'what it Indicates' => 'publisher pdf'
                                                                }
                                                              ])
      end

      it 'returns a positive score' do
        expect(calculator.score).to eq(1)
      end
    end

    context 'when rule indicates accepted version' do
      before do
        allow(calculator).to receive(:rules_lines).and_return([
                                                                {
                                                                  'what to search' => 'paper.pdf',
                                                                  'where to search' => 'filename',
                                                                  'how to search' => 'string',
                                                                  'what it Indicates' => 'acceptedVersion'
                                                                }
                                                              ])
      end

      it 'returns a negative score' do
        expect(calculator.score).to eq(-1)
      end
    end

    context 'when rules file does not exist' do
      before do
        allow(calculator).to receive(:rules_lines).and_call_original
        allow(File).to receive(:exist?).and_return(false)
      end

      it 'raises a clear error' do
        expect { calculator.score }
          .to raise_error(RuntimeError, 'Error: config/file_version_checking_rules.csv does not exist or cannot be read.')
      end
    end

    context 'when parser raises a PDF::Reader error while extracting content' do
      let(:pages) do
        raise PDF::Reader::MalformedPDFError
      end

      it 'returns zero' do
        expect(calculator.score).to eq(0)
      end
    end

    context 'when one page fails but another page succeeds' do
      let(:first_page) { instance_double(PDF::Reader::Page) }
      let(:second_page) { instance_double(PDF::Reader::Page, text: 'found phrase') }
      let(:pages) { [first_page, second_page] }

      before do
        allow(first_page).to receive(:text).and_raise(StandardError)
        allow(calculator).to receive(:rules_lines).and_return([
                                                                {
                                                                  'what to search' => 'found phrase',
                                                                  'where to search' => 'file',
                                                                  'how to search' => 'string',
                                                                  'what it Indicates' => 'publisher pdf'
                                                                }
                                                              ])
      end

      it 'continues processing and scores based on remaining pages' do
        expect(calculator.score).to eq(1)
      end
    end
  end
end
