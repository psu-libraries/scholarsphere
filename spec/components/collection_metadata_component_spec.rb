# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionMetadataComponent, type: :component do
  let(:result) { render_inline(described_class.new(collection: collection)) }

  describe 'rendering' do
    let(:collection) { Collection.new(
      subtitle: 'My subtitle',
      created_at: Time.zone.parse('2020-01-15 16:07'),
      keyword: %w(one two),
      description: nil,
      subject: []
    ) }

    it 'renders a string with label' do
      expect(result.css('dt.collection-subtitle').text).to eq 'Subtitle'
      expect(result.css('dd.collection-subtitle').text).to eq 'My subtitle'
    end

    it 'renders a date with a nice format' do
      expect(result.css('dd.collection-created-at').text).to eq 'January 15, 2020 16:07'
    end

    it 'renders a multi-value field' do
      expect(result.css('dd.collection-keyword .multiple-member').map(&:text))
        .to contain_exactly('one', 'two')

      expect(result.css('dd.collection-keyword').text).to include('; ')
    end

    it 'does not render any fields that are empty' do
      expect(result.css('dd.collection-description')).to be_empty
      expect(result.css('dd.collection-subject')).to be_empty
    end

    it 'accepts a decorated and non-decorated Collection' do
      non_decorated_result = render_inline(described_class.new(collection: collection))
      expect(non_decorated_result.css('dt.collection-subtitle')).to be_present

      decorated_result = render_inline(described_class.new(collection: ResourceDecorator.new(collection)))
      expect(decorated_result.css('dt.collection-subtitle')).to be_present
    end
  end

  describe 'fully loaded' do
    let(:collection) { build_stubbed :collection, :with_complete_metadata, :with_creators }

    it 'renders every field' do
      # Titles
      expect(result.css('dt.collection-title')).to be_present
      expect(result.css('dt.collection-subtitle')).to be_present
      expect(result.css('dt.collection-description')).to be_present
      expect(result.css('dt.collection-keyword')).to be_present
      expect(result.css('dt.collection-contributor')).to be_present
      expect(result.css('dt.collection-publisher')).to be_present
      expect(result.css('dt.collection-display-published-date')).to be_present
      expect(result.css('dt.collection-subject')).to be_present
      expect(result.css('dt.collection-language')).to be_present
      expect(result.css('dt.collection-identifier')).to be_present
      expect(result.css('dt.collection-based-near')).to be_present
      expect(result.css('dt.collection-related-url')).to be_present
      expect(result.css('dt.collection-source')).to be_present
      expect(result.css('dt.collection-created-at')).to be_present
      expect(result.css('dt.collection-creator-aliases')).to be_present

      # Test that the fields have the correct values. Please note that some of
      # the more exotic field type (multiples, dates, iso8601 strings) are only
      # rudimentarily tested here, because they're unit-tested in detail above.
      expect(result.css('dd.collection-title').text).to eq collection[:title]
      expect(result.css('dd.collection-subtitle').text).to eq collection[:subtitle]
      expect(result.css('dd.collection-creator-aliases').text).to include collection.creator_aliases.map(&:alias).first
      expect(result.css('dd.collection-description').text).to include collection[:description].first
      expect(result.css('dd.collection-keyword').text).to include collection[:keyword].first
      expect(result.css('dd.collection-contributor').text).to include collection[:contributor].first
      expect(result.css('dd.collection-publisher').text).to include collection[:publisher].first
      expect(result.css('dd.collection-display-published-date').text)
        .to include Time.zone.parse(collection[:published_date]).year.to_s
      expect(result.css('dd.collection-subject').text).to include collection[:subject].first
      expect(result.css('dd.collection-language').text).to include collection[:language].first
      expect(result.css('dd.collection-identifier').text).to include collection[:identifier].first
      expect(result.css('dd.collection-based-near').text).to include collection[:based_near].first
      expect(result.css('dd.collection-related-url').text).to include collection[:related_url].first
      expect(result.css('dd.collection-source').text).to include collection[:source].first
      expect(result.css('dd.collection-created-at').text).to include collection[:created_at].year.to_s
    end
  end
end
