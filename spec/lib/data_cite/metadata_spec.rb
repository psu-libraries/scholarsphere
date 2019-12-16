# frozen_string_literal: true

require 'spec_helper'
require 'data_cite'
require 'factory_bot'

RSpec.describe DataCite::Metadata do
  subject(:metadata) { described_class.new(work_version: work_version) }

  let(:attributes) { metadata.attributes }

  let(:work_version) { FactoryBot.build_stubbed :work_version, :with_complete_metadata }
  let(:work) { work_version.work }

  describe '#initialize' do
    it 'accepts a WorkVersion' do
      metadata = described_class.new(work_version: work_version)
      expect(metadata.work_version).to eq work_version
    end
  end

  describe '#attributes' do
    context 'when given the happy path' do
      it "maps the given WorkVersion's attributes into ones needed by DataCite" do
        expect(attributes[:titles]).to eq([{ title: work_version.title }])
        expect(attributes[:creators]).to eq(
          [{
            givenName: work_version.work.depositor.given_name,
            familyName: work_version.work.depositor.surname
          }]
        )

        # The following are tested thoroughly below
        expect(attributes[:publicationYear]).to be_present
        expect(attributes.dig(:types, :resourceTypeGeneral)).to be_present
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
