# frozen_string_literal: true

require 'rails_helper'
require 'support/vcr'

RSpec.describe RmdPublication, :vcr do
  context 'when publication is found' do
    describe '#title' do
      let(:rmd_publication) { described_class.new('https://doi.org/10.1038/abcdefg1234567') }

      it 'returns the title value for the received publication' do
        expect(rmd_publication.title).to eq 'A Scholarly Research Article'
      end
    end

    describe '#secondary_title' do
      let(:rmd_publication) { described_class.new('https://doi.org/10.1038/abcdefg1234567') }

      it 'returns the secondary_title value for the received publication' do
        expect(rmd_publication.secondary_title).to eq 'A Comparative Analysis'
      end
    end

    describe '#abstract' do
      let(:rmd_publication) { described_class.new('https://doi.org/10.1038/abcdefg1234567') }

      it 'returns the abstract value for the received publication' do
        expect(rmd_publication.abstract).to eq 'A summary of the research'
      end
    end

    describe '#preferred_open_access_url' do
      let(:rmd_publication) { described_class.new('https://doi.org/10.1038/abcdefg1234567') }

      it 'returns the preferred_open_access_url value for the received publication' do
        expect(rmd_publication.preferred_open_access_url).to eq 'https://example.org/articles/article-123.pdf'
      end
    end

    describe '#publisher' do
      let(:rmd_publication) { described_class.new('https://doi.org/10.1038/abcdefg1234567') }

      it 'returns the publisher value for the received publication' do
        expect(rmd_publication.publisher).to eq 'An Academic Journal'
      end
    end

    describe '#published_on' do
      let(:rmd_publication) { described_class.new('https://doi.org/10.1038/abcdefg1234567') }

      it 'returns the published_on value for the received publication' do
        expect(rmd_publication.published_on).to eq '2010-12-05'
      end
    end

    describe '#contributors' do
      let(:rmd_publication) { described_class.new('https://doi.org/10.1038/abcdefg1234567') }

      it 'returns an array of contributor structs for the received publication' do
        contributor = Struct.new(:first_name, :middle_name, :last_name, :psu_user_id, :position)
        contributors = [contributor.new('Anne', 'Example', 'Contributor', 'abc1234', 1),
                        contributor.new('Joe', 'Fakeman', 'Person', 'def1234', 2),
                        contributor.new('Another', 'Fake', 'Contributor', '', 3)]
        expect(rmd_publication.contributors.map(&:to_h)).to eq contributors.map(&:to_h)
      end
    end

    describe '#tags' do
      let(:rmd_publication) { described_class.new('https://doi.org/10.1038/abcdefg1234567') }

      it 'returns an array of tags for the received publication' do
        expect(rmd_publication.tags).to eq ['A Topic', 'Another Topic']
      end
    end
  end

  context 'when publication is not found' do
    let(:rmd_publication) { described_class.new('https://doi.org/10.1038/abcdefg1234567') }

    it 'raises a PublicationNotFound error' do
      expect { rmd_publication.title }.to raise_error RmdPublication::PublicationNotFound
    end
  end

  context 'when an error is returned from the api' do
    let(:rmd_publication) { described_class.new('https://doi.org/10.1038/abcdefg1234567') }

    it 'raises a RmdClientError' do
      expect { rmd_publication.title }.to raise_error RmdClient::RmdClientError, 'Unauthorized'
    end
  end
end
