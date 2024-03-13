# frozen_string_literal: true

require 'rails_helper'
require 'support/vcr'

RSpec.describe RmdPublication, :vcr do
  let(:rmd_publication) { described_class.new('https://doi.org/10.1038/abcdefg1234567') }
  describe '#title' do
    it 'returns the title value for the received publication' do
      expect(rmd_publication.title).to eq 'A Scholarly Research Article'
    end
  end

  describe '#secondary_title' do
    it 'returns the secondary_title value for the received publication' do
      expect(rmd_publication.secondary_title).to eq 'A Comparative Analysis'
    end
  end

  describe '#abstract' do
    it 'returns the abstract value for the received publication' do
      expect(rmd_publication.abstract).to eq 'A summary of the research'
      
    end
  end

  describe '#preferred_open_access_url' do
    it 'returns the preferred_open_access_url value for the received publication' do
      expect(rmd_publication.preferred_open_access_url).to eq 'https://example.org/articles/article-123.pdf'
      
    end
  end

  describe '#publisher' do
    it 'returns the publisher value for the received publication' do
      expect(rmd_publication.publisher).to eq 'A Publishing Company'
      
    end
  end

  describe '#published_on' do
    it 'returns the published_on value for the received publication' do
      expect(rmd_publication.published_on).to eq '2010-12-05'
      
    end
  end

  describe '#supplementary_url' do
    it 'returns the supplementary_url value for the received publication' do
      expect(rmd_publication.supplementary_url).to eq 'https://blog.com/post'
      
    end
  end

  describe '#contributors' do
    it 'returns an array of contributor structs for the received publication' do
      expect(rmd_publication.contributors).to eq 'A Scholarly Research Article'
      
    end
  end

  describe '#tags' do
    it 'returns an array of tags for the received publication' do
      expect(rmd_publication.tags).to eq ["A Topic"]
      
    end
  end
end
