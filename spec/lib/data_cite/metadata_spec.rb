# frozen_string_literal: true

require 'spec_helper'
require 'data_cite'

RSpec.describe DataCite::Metadata do
  subject(:metadata) { described_class.new(work_version: work_version, public_identifier: uuid) }

  let(:uuid) { 'abc-123' }

  let(:attributes) { metadata.attributes }

  let(:work_version) { FactoryBot.build_stubbed :work_version, :with_complete_metadata, creators: [creator] }
  let(:work) { work_version.work }

  let(:creator) { FactoryBot.build_stubbed :actor, orcid: nil }

  before do
    metadata.public_url_source = ->(id) { "http://example.test/resources/#{id}" }
  end

  describe '#initialize' do
    it 'accepts a WorkVersion and public identifier (uuid)' do
      metadata = described_class.new(work_version: work_version, public_identifier: uuid)
      expect(metadata.work_version).to eq work_version
      expect(metadata.public_identifier).to eq uuid
    end
  end

  describe '#attributes' do
    context 'when given the happy path' do
      it "maps the given WorkVersion's attributes into ones needed by DataCite" do
        expect(attributes[:titles]).to eq([{ title: work_version.title }])

        # The following are tested thoroughly below
        expect(attributes[:url]).to be_present
        expect(attributes[:creators]).to be_present
        expect(attributes[:publicationYear]).to be_present
        expect(attributes.dig(:types, :resourceTypeGeneral)).to be_present
      end

      describe 'url generation' do
        before do
          metadata.public_url_source = nil # Clear a previously injected mock
        end

        it 'uses the real public URL for a resource' do
          expected_url = Rails.application.routes.url_helpers.resource_url(uuid)
          expect(attributes[:url]).to eq expected_url
        end
      end
    end

    context 'when given variants of the publication year' do
      subject(:publicationYear) { attributes[:publicationYear] }

      context 'when the publication_date can be parsed' do
        before { work_version.published_date = ['2019-12-16'] }

        it 'parses the publication_date and uses the year' do
          expect(publicationYear).to eq 2019
        end
      end

      context 'when the publication_date cannot be parsed' do
        before do
          work_version.published_date = ['nonsense']
          work_version.created_at = Time.zone.parse('2019-12-16')
        end

        it 'uses the year from the date the record was created' do
          expect(publicationYear).to eq 2019
        end
      end
    end

    context 'when given variants of the work_type' do
      context 'when work_type is DATASET' do
        before { allow(work).to receive(:work_type).and_return(Work::Types::DATASET) }

        it 'maps to the correct resource type' do
          expect(attributes.dig(:types, :resourceTypeGeneral)).to eq 'Dataset'
        end
      end
    end

    context 'when the creators may or may not have ORCiDs' do
      subject(:first_creator) { attributes[:creators].first }

      context 'when the creator has no orcid' do
        before { creator.orcid = nil }

        it "sets the creator's name" do
          expect(first_creator).to eq(
            name: work_version.creator_aliases.first.alias
          )
        end
      end

      context 'when the creator has an ORCiD' do
        before { creator.orcid = '1111-2222-3333-4444' }

        it "sets the creator's name and provides the ORCiD" do
          expect(first_creator).to eq(
            name: work_version.creator_aliases.first.alias,
            nameIdentifiers: [
              {
                nameIdentifier: '1111-2222-3333-4444',
                nameIdentifierScheme: 'ORCID',
                schemeUri: 'http://orcid.org/'
              }
            ]
          )
        end
      end
    end
  end

  describe '#validate! and #valid?' do
    context 'when title is blank' do
      before { work_version.title = nil }

      it { expect { metadata.validate! }.to raise_error(described_class::ValidationError) }
      it { expect(metadata).not_to be_valid }
    end

    context 'when publication_date and created_at are empty/blank' do
      before do
        work_version.published_date = []
        work_version.created_at = nil
      end

      it { expect { metadata.validate! }.to raise_error(described_class::ValidationError) }
      it { expect(metadata).not_to be_valid }
    end

    context 'when work_type is empty' do
      before { work.work_type = nil }

      it { expect { metadata.validate! }.to raise_error(described_class::ValidationError) }
      it { expect(metadata).not_to be_valid }
    end
  end
end
