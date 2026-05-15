# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenAccessVersion::ExifChecker do
  describe '#version' do
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
