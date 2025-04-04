# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdobePdf::AccessibilityChecker, :vcr do
  let(:checker) { described_class.new(resource) }

  describe '#initialize' do
    context 'when the file size exceeds the limit' do
      let(:resource) { instance_double('FileResource', file_data: { 'metadata' => { 'size' => file_size } }) }
      let(:file_size) { described_class::FILE_SIZE_LIMIT * 1.5 }

      it 'raises a FileSizeExceededError' do
        expect { checker }.to raise_error(AdobePdf::AccessibilityChecker::FileSizeExceededError, 'File size exceeds the limit of 100Mb')
      end
    end

    context 'when the file size does not exceed the limit' do
      let(:resource) { instance_double('FileResource', file_data: { 'metadata' => { 'size' => file_size } }) }
      let(:file_size) { described_class::FILE_SIZE_LIMIT * 0.5 }

      it 'does not raise an error' do
        expect { checker }.not_to raise_error
      end
    end
  end

  describe '#call' do
    let(:resource) { create(:file_resource, :pdf) }

    # Turn off vcr here for a full, live integration test
    describe 'happy path' do
      it 'fetches the accessibility report' do
        expect { checker.call }.to change(AccessibilityCheckResult, :count).by(1)
        expect(AccessibilityCheckResult.last.detailed_report)
          .to eq({
                   'Detailed Report' => {
                     'Alternate Text' => [
                       { 'Description' => 'Figures require alternate text', 'Rule' => 'Figures alternate text',
                         'Status' => 'Failed' },
                       { 'Description' => 'Alternate text that will never be read',
                         'Rule' => 'Nested alternate text', 'Status' => 'Failed' },
                       { 'Description' => 'Alternate text must be associated with some content',
                         'Rule' => 'Associated with content', 'Status' => 'Failed' },
                       { 'Description' => 'Alternate text should not hide annotation',
                         'Rule' => 'Hides annotation', 'Status' => 'Failed' },
                       { 'Description' => 'Other elements that require alternate text',
                         'Rule' => 'Other elements alternate text', 'Status' => 'Failed' }
                     ],
                     'Document' => [
                       { 'Description' => 'Accessibility permission flag must be set',
                         'Rule' => 'Accessibility permission flag', 'Status' => 'Passed' },
                       { 'Description' => 'Document is not image-only PDF', 'Rule' => 'Image-only PDF',
                         'Status' => 'Passed' },
                       { 'Description' => 'Document is tagged PDF', 'Rule' => 'Tagged PDF',
                         'Status' => 'Failed' },
                       { 'Description' => 'Document structure provides a logical reading order', 'Rule' => 'Logical Reading Order',
                         'Status' => 'Needs manual check' },
                       { 'Description' => 'Text language is specified', 'Rule' => 'Primary language',
                         'Status' => 'Failed' },
                       { 'Description' => 'Document title is showing in title bar', 'Rule' => 'Title',
                         'Status' => 'Failed' },
                       { 'Description' => 'Bookmarks are present in large documents', 'Rule' => 'Bookmarks',
                         'Status' => 'Passed' },
                       { 'Description' => 'Document has appropriate color contrast',
                         'Rule' => 'Color contrast', 'Status' => 'Needs manual check' }
                     ],
                     'Forms' => [
                       { 'Description' => 'All form fields are tagged', 'Rule' => 'Tagged form fields',
                         'Status' => 'Passed' },
                       { 'Description' => 'All form fields have description', 'Rule' => 'Field descriptions',
                         'Status' => 'Passed' }
                     ],
                     'Headings' => [
                       { 'Description' => 'Appropriate nesting', 'Rule' => 'Appropriate nesting',
                         'Status' => 'Failed' }
                     ],
                     'Lists' => [
                       { 'Description' => 'LI must be a child of L', 'Rule' => 'List items',
                         'Status' => 'Failed' },
                       { 'Description' => 'Lbl and LBody must be children of LI', 'Rule' => 'Lbl and LBody',
                         'Status' => 'Failed' }
                     ],
                     'Page Content' => [
                       { 'Description' => 'All page content is tagged', 'Rule' => 'Tagged content',
                         'Status' => 'Failed' },
                       { 'Description' => 'All annotations are tagged', 'Rule' => 'Tagged annotations',
                         'Status' => 'Passed' },
                       { 'Description' => 'Tab order is consistent with structure order',
                         'Rule' => 'Tab order', 'Status' => 'Failed' },
                       { 'Description' => 'Reliable character encoding is provided',
                         'Rule' => 'Character encoding', 'Status' => 'Passed' },
                       { 'Description' => 'All multimedia objects are tagged', 'Rule' => 'Tagged multimedia',
                         'Status' => 'Passed' },
                       { 'Description' => 'Page will not cause screen flicker', 'Rule' => 'Screen flicker',
                         'Status' => 'Passed' },
                       { 'Description' => 'No inaccessible scripts', 'Rule' => 'Scripts',
                         'Status' => 'Passed' },
                       { 'Description' => 'Page does not require timed responses', 'Rule' => 'Timed responses',
                         'Status' => 'Passed' },
                       { 'Description' => 'Navigation links are not repetitive', 'Rule' => 'Navigation links',
                         'Status' => 'Passed' }
                     ],
                     'Tables' => [
                       { 'Description' => 'TR must be a child of Table, THead, TBody, or TFoot',
                         'Rule' => 'Rows', 'Status' => 'Failed' },
                       { 'Description' => 'TH and TD must be children of TR', 'Rule' => 'TH and TD',
                         'Status' => 'Failed' },
                       { 'Description' => 'Tables should have headers', 'Rule' => 'Headers',
                         'Status' => 'Failed' },
                       { 'Description' => 'Tables must contain the same number of columns in each row and rows in each column', 'Rule' => 'Regularity',
                         'Status' => 'Failed' },
                       { 'Description' => 'Tables must have a summary', 'Rule' => 'Summary',
                         'Status' => 'Failed' }
                     ]
                   },
                   'Summary' => {
                     'Description' => 'The checker found problems which may prevent the document from being fully accessible.',
                     'Failed' => 18,
                     'Failed manually' => 0,
                     'Needs manual check' => 2,
                     'Passed' => 12,
                     'Passed manually' => 0,
                     'Skipped' => 0
                   }
                 })
      end
    end

    # Slow test.  1+ minutes to complete
    describe 'when polling takes too long', :slow do
      around do |example|
        VCR.configure do |config|
          original_options = config.default_cassette_options.dup
          # Allow playback repeats to simulate polling taking too long
          config.default_cassette_options[:allow_playback_repeats] = true

          example.run

          # Restore original configuration after the test
          config.default_cassette_options = original_options
        end
      end

      it 'stores an error in the AccessibilityChecker report field' do
        expect { checker.call }.to change(AccessibilityCheckResult, :count).by(1)
        expect(AccessibilityCheckResult.last.detailed_report).to eq({ 'error' => 'Accessibility check failed: Polling time limit exceeded' })
      end
    end

    describe "when there's an error fetching the access token" do
      it 'an AdobePdfApiError is raised' do
        expect { checker.call }.to raise_error(AdobePdf::Base::AdobePdfApiError,
                                               'Authentication failed: 400 - {"error":{"code":"invalid_client","message":"invalid client_id parameter"}}')
      end
    end

    describe "when there's an error fetching the asset upload uri and asset id" do
      it 'an AdobePdfApiError is raised' do
        expect { checker.call }.to raise_error(AdobePdf::Base::AdobePdfApiError,
                                               'Failed to get presigned URL: 400 - {"error": {"code": "BAD_REQUEST","message": "Bad Request."}}')
      end
    end

    describe "when there's an error while uploading the pdf to adobe" do
      it 'an AdobePdfApiError is raised' do
        expect { checker.call }.to raise_error(
          AdobePdf::Base::AdobePdfApiError,
          /Failed to upload file: 403 - <\?xml version=\\"1.0\\" encoding=\\"UTF-8\\"\?>\\n<Error><Code>AccessDenied</
        )
      end
    end

    describe "when there's an error initiating the accessibility checker" do
      it 'an AdobePdfApiError is raised' do
        expect { checker.call }.to raise_error(
          AdobePdf::Base::AdobePdfApiError,
          'Failed to run PDF Accessibility Checker: 404 - {"error": {"code": "NOT_FOUND","message": "Asset not found."}}'
        )
      end
    end

    describe "when there's an error polling the accessibility checker" do
      it 'an AdobePdfApiError is raised' do
        expect { checker.call }.to raise_error(
          AdobePdf::Base::AdobePdfApiError,
          'Failed to get Accessibility Checker status: 404 - {"error":{"code": "NOT_FOUND","message": "Job not found."}}'
        )
      end
    end

    describe "when there's an error fetching the accessibility report" do
      it 'an AdobePdfApiError is raised' do
        expect { checker.call }.to raise_error(
          AdobePdf::Base::AdobePdfApiError,
          /Failed to fetch JSON from presigned URL: 404 - <\?xml version=\\"1.0\\" encoding=\\"UTF-8\\"\?><Error><Code>AccessDenied/
        )
      end
    end

    describe "when there's an error deleting the asset" do
      let(:logger) { instance_spy('Logger') }

      before do
        allow(Logger).to receive(:new).and_return(logger)
      end

      it 'an AdobePdfApiError is raised' do
        checker.call

        expect(logger).to have_received(:error).with(/Failed to delete asset: 500/)
      end
    end

    describe 'any other error' do
      it 'raises that error' do
        allow(Faraday).to receive(:post).and_raise(StandardError, 'Some other error')
        expect { checker.call }.to raise_error(StandardError, 'Some other error')
      end
    end
  end
end
