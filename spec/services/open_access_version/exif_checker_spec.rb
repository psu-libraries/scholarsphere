# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenAccessVersion::ExifChecker do
  subject(:exif_file_version) { described_class.new(io: io, publisher: publisher) }

  let(:io) { StringIO.new('fake pdf bytes') }
  let(:publisher) { nil }
  let(:exif_data) { nil }
  let(:exif_tool) { double 'ExifTool', to_hash: exif_data }

  before {
    allow(Exiftool).to receive(:new).and_return(exif_tool)
  }

  describe '#version' do
    context 'when no exif data' do
      it 'returns nil' do
        expect(exif_file_version.version).to be_nil
      end
    end

    context 'when exif data exists' do
      context 'when file is not Accepted Manuscript or Final Publshed Version"' do
        let(:exif_data) { { journal_article_version: 'no_version', subject: 'other subject' } }

        it 'returns nil' do
          expect(exif_file_version.version).to be_nil
        end
      end

      context 'when creator field contains an integer' do
        let(:exif_data) { { creator: 1 } }

        it 'returns nil' do
          expect(exif_file_version.version).to be_nil
        end
      end

      context 'when creator_tool field contains an integer' do
        let(:exif_data) { { creator_tool: 1 } }

        it 'returns nil' do
          expect(exif_file_version.version).to be_nil
        end
      end

      context 'when exif data validates both Accepted Manuscript and Final Publshed Version' do
        let(:exif_data) { { journal_article_version: 'am', subject: 'downloaded from' } }

        it 'returns Accepted Manuscript' do
          expect(exif_file_version.version).to eq OpenAccessVersion::VersionValues::ACCEPTED
        end
      end

      context 'when file is Accepted Manuscript' do
        let(:exif_data) { { journal_article_version: 'am' } }

        context 'when journal article version field is "am"' do
          it 'returns Accepted Manuscript' do
            expect(exif_file_version.version).to eq OpenAccessVersion::VersionValues::ACCEPTED
          end
        end
      end

      context 'when file is Final Published Version' do
        context 'when journal article version field is "p"' do
          let(:exif_data) { { journal_article_version: 'p' } }

          it 'returns Final Published Version' do
            expect(exif_file_version.version).to eq OpenAccessVersion::VersionValues::PUBLISHED
          end
        end

        context 'when journal article version field is "vor"' do
          let(:exif_data) { { journal_article_version: 'vor' } }

          it 'returns Final Published Version' do
            expect(exif_file_version.version).to eq OpenAccessVersion::VersionValues::PUBLISHED
          end
        end

        context 'when right_en_gb field has RIGHTS_EN_GB_TEXT' do
          let(:exif_data) { { rights_en_gb: OpenAccessVersion::ExifChecker::RIGHTS_EN_GB_TEXT } }

          it 'returns Final Published Version' do
            expect(exif_file_version.version).to eq OpenAccessVersion::VersionValues::PUBLISHED
          end
        end

        context 'when wps_journaldoi field is not empty' do
          let(:exif_data) { { wps_journaldoi: 'wps_journaldoi' } }

          it 'returns Final Published Version' do
            expect(exif_file_version.version).to eq OpenAccessVersion::VersionValues::PUBLISHED
          end
        end

        context 'when subject field has name of journal' do
          let(:publisher) { 'name_of_publisher' }
          let(:exif_data) { { subject: publisher } }

          it 'returns Final Published Version' do
            expect(exif_file_version.version).to eq OpenAccessVersion::VersionValues::PUBLISHED
          end
        end

        context 'when subject field includes "downloaded from"' do
          let(:exif_data) { { subject: 'downloaded from xyz' } }

          it 'returns Final Published Version' do
            expect(exif_file_version.version).to eq OpenAccessVersion::VersionValues::PUBLISHED
          end
        end

        context 'when subject field is "journal pre-proof"' do
          let(:exif_data) { { subject: 'journal pre-proof' } }

          it 'returns Final Published Version' do
            expect(exif_file_version.version).to eq OpenAccessVersion::VersionValues::PUBLISHED
          end
        end

        context 'when subject field is an Array that contains "journal pre-proof"' do
          let(:exif_data) { { subject: ['other', 'journal pre-proof'] } }

          it 'returns Final Published Version' do
            expect(exif_file_version.version).to eq OpenAccessVersion::VersionValues::PUBLISHED
          end
        end

        context 'when rendition_class field is "proof:pdf"' do
          let(:exif_data) { { rendition_class: 'proof:pdf' } }

          it 'returns Final Published Version' do
            expect(exif_file_version.version).to eq OpenAccessVersion::VersionValues::PUBLISHED
          end
        end

        context 'when creator field is one of the PUBLISHED_VERSION_CREATORS' do
          let(:exif_data) { { creator: OpenAccessVersion::ExifChecker::PUBLISHED_VERSION_CREATORS.sample } }

          it 'returns Final Published Version' do
            expect(exif_file_version.version).to eq OpenAccessVersion::VersionValues::PUBLISHED
          end
        end

        context 'when creator field is LaTeX' do
          let(:exif_data) { { creator: 'LaTeX' } }

          it 'returns nil' do
            expect(exif_file_version.version).to eq nil
          end
        end

        context 'when creator_tool field is one of the PUBLISHED_VERSION_CREATORS value' do
          let(:exif_data) { { creator_tool: OpenAccessVersion::ExifChecker::PUBLISHED_VERSION_CREATORS.sample } }

          it 'returns Final Published Version' do
            expect(exif_file_version.version).to eq OpenAccessVersion::VersionValues::PUBLISHED
          end
        end

        context 'when creator_tool field is LaTeX' do
          let(:exif_data) { { creator_tool: 'LaTeX' } }

          it 'returns nil' do
            expect(exif_file_version.version).to eq nil
          end
        end

        context 'when producer field is "Project MUSE"' do
          let(:exif_data) { { producer: 'Project MUSE' } }

          it 'returns Final Published Version' do
            expect(exif_file_version.version).to eq OpenAccessVersion::VersionValues::PUBLISHED
          end
        end
      end
    end

    context 'when required io is missing' do
      it 'raises a keyword argument error' do
        expect { described_class.new(publisher: nil) }
          .to raise_error(ArgumentError, /missing keyword: :io/)
      end
    end

    context 'when using io input' do
      subject(:checker) { described_class.new(io: io, publisher: nil) }

      let(:io) { StringIO.new('fake pdf bytes') }

      it 'passes the io object directly to Exiftool' do
        exiftool = instance_double(Exiftool, to_hash: { journal_article_version: 'vor' })
        allow(Exiftool).to receive(:new).with(io).and_return(exiftool)

        expect(checker.version).to eq(OpenAccessVersion::VersionValues::PUBLISHED)
      end
    end
  end
end
