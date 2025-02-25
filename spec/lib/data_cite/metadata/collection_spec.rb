# frozen_string_literal: true

require 'rails_helper'
require 'data_cite'

RSpec.describe DataCite::Metadata::Collection do
  subject(:metadata) { described_class.new(resource: collection, public_identifier: uuid) }

  let(:uuid) { 'abc-123' }

  let(:attributes) { metadata.attributes }

  let(:collection) { FactoryBot.build_stubbed(:collection, :with_complete_metadata, creators: [creator]) }

  let(:creator) { FactoryBot.build_stubbed(:authorship, :with_actor) }

  before do
    metadata.public_url_source = ->(id) { "http://example.test/resources/#{id}" }
  end

  describe '#initialize' do
    it 'accepts a Collection and public identifier (uuid)' do
      metadata = described_class.new(resource: collection, public_identifier: uuid)
      expect(metadata.resource).to eq collection
      expect(metadata.public_identifier).to eq uuid
    end
  end

  describe '#attributes' do
    context 'when given the happy path' do
      it "maps the given Collection's attributes into ones needed by DataCite" do
        expect(attributes[:titles]).to eq([{ title: collection.title }])

        # The following are tested thoroughly below
        expect(attributes[:url]).to be_present
        expect(attributes[:creators]).to be_present
        expect(attributes[:publicationYear]).to be_present
        expect(attributes.dig(:types, :resourceTypeGeneral)).to eq 'Collection'
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
        before { collection.published_date = '2019-12-16' }

        it 'parses the publication_date and uses the year' do
          expect(publicationYear).to eq 2019
        end
      end

      context 'when the publication_date cannot be parsed' do
        before do
          collection.published_date = 'nonsense'
          collection.created_at = Time.zone.parse('2019-12-16')
        end

        it 'uses the year from the date the record was created' do
          expect(publicationYear).to eq 2019
        end
      end
    end

    context 'when the creators may or may not have ORCiDs' do
      subject(:first_creator) { attributes[:creators].first }

      context 'when the creator has no orcid' do
        let(:creator) { FactoryBot.build_stubbed(:authorship, actor: build(:actor, :without_an_orcid)) }

        it "sets the creator's name" do
          expect(first_creator).to eq(
            name: collection.creators.first.display_name
          )
        end
      end

      context 'when the creator has an ORCiD' do
        it "sets the creator's name and provides the ORCiD" do
          expect(first_creator).to eq(
            name: collection.creators.first.display_name,
            nameIdentifiers: [
              {
                nameIdentifier: creator.actor.orcid,
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
      before { collection.title = nil }

      it { expect { metadata.validate! }.to raise_error(DataCite::Metadata::ValidationError) }
      it { expect(metadata).not_to be_valid }
    end

    context 'when publication_date and created_at are empty/blank' do
      before do
        collection.published_date = nil
        collection.created_at = nil
      end

      it { expect { metadata.validate! }.to raise_error(DataCite::Metadata::ValidationError) }
      it { expect(metadata).not_to be_valid }
    end
  end
end
