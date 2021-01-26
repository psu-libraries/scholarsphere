# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionMetadataComponent, type: :component do
  let(:decorated_collection) { ResourceDecorator.new(collection) }
  let(:result) { render_inline(described_class.new(collection: decorated_collection)) }

  # MintableDoiComponent uses the `helpers` method to access a Pundit policy, to
  # determine whether the `current_user` has the ability to mint a doi. This is
  # entirely too much setup for this unit test.
  #
  # Instead, MintableDoiComponent also has the ability to inject our own
  # "policy" using the minting_policy_source method. Below, we intercept any
  # calls to MintableDoiComponent.new, allow them to execute as normal, then
  # inject our own policy, so that we don't have to set up the Pundit one
  before do
    allow(MintableDoiComponent).to(receive(:new)).and_wrap_original do |method, *args|
      method
        .call(*args)
        .tap { |new_component_instance| new_component_instance.minting_policy_source = ->(_) { true } }
    end
  end

  describe 'rendering' do
    let(:collection) { build_stubbed :collection,
                                     subtitle: 'My subtitle',
                                     deposited_at: Time.zone.parse('2020-01-15 16:07'),
                                     keyword: %w(one two),
                                     subject: []
    }

    it 'renders a string with label' do
      expect(result.css('th.collection-subtitle').text).to eq 'Subtitle'
      expect(result.css('td.collection-subtitle').text).to eq 'My subtitle'
    end

    it 'renders a date with a nice format' do
      expect(result.css('td.collection-deposited-at').text).to eq 'January 15, 2020 16:07'
    end

    it 'renders a multi-value field' do
      expect(result.css('td.collection-keyword .multiple-member').map(&:text))
        .to contain_exactly('one', 'two')

      expect(result.css('td.collection-keyword').text).to include('; ')
    end

    it 'does not render any fields that are empty' do
      expect(result.css('td.collection-subject')).to be_empty
    end

    it 'accepts a decorated and non-decorated Collection' do
      non_decorated_result = render_inline(described_class.new(collection: collection))
      expect(non_decorated_result.css('th.collection-subtitle')).to be_present

      decorated_result = render_inline(described_class.new(collection: ResourceDecorator.new(collection)))
      expect(decorated_result.css('th.collection-subtitle')).to be_present
    end
  end

  describe 'fully loaded' do
    let(:collection) { build_stubbed :collection, :with_complete_metadata, :with_creators }

    it 'renders every field' do
      # Titles
      expect(result.css('th.collection-title')).to be_present
      expect(result.css('th.collection-subtitle')).to be_present
      expect(result.css('th.collection-keyword')).to be_present
      expect(result.css('th.collection-contributor')).to be_present
      expect(result.css('th.collection-publisher')).to be_present
      expect(result.css('th.collection-display-published-date')).to be_present
      expect(result.css('th.collection-subject')).to be_present
      expect(result.css('th.collection-language')).to be_present
      expect(result.css('th.collection-identifier')).to be_present
      expect(result.css('th.collection-based-near')).to be_present
      expect(result.css('th.collection-related-url')).to be_present
      expect(result.css('th.collection-source')).to be_present
      expect(result.css('th.collection-deposited-at')).to be_present
      expect(result.css('th.collection-creators')).to be_present

      # Test that the fields have the correct values. Please note that some of
      # the more exotic field type (multiples, dates, iso8601 strings) are only
      # rudimentarily tested here, because they're unit-tested in detail above.
      expect(result.css('td.collection-title').text).to eq collection[:title]
      expect(result.css('td.collection-subtitle').text).to eq collection[:subtitle]
      expect(result.css('td.collection-creators').text).to include collection.creators.map(&:alias).first
      expect(result.css('td.collection-keyword').text).to include collection[:keyword].first
      expect(result.css('td.collection-contributor').text).to include collection[:contributor].first
      expect(result.css('td.collection-publisher').text).to include collection[:publisher].first
      expect(result.css('td.collection-display-published-date').text)
        .to include Time.zone.parse(collection[:published_date]).year.to_s
      expect(result.css('td.collection-subject').text).to include collection[:subject].first
      expect(result.css('td.collection-language').text).to include collection[:language].first
      expect(result.css('td.collection-identifier').text).to include collection[:identifier].first
      expect(result.css('td.collection-based-near').text).to include collection[:based_near].first
      expect(result.css('td.collection-related-url').text).to include collection[:related_url].first
      expect(result.css('td.collection-source').text).to include collection[:source].first
      expect(result.css('td.collection-deposited-at').text).to include collection[:deposited_at].year.to_s
    end
  end
end
