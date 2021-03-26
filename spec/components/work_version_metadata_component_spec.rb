# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersionMetadataComponent, type: :component do
  let(:decorated_work_version) { WorkVersionDecorator.new(work_version) }
  let(:result) { render_inline(described_class.new(work_version: decorated_work_version)) }

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
    let(:work) { build_stubbed :work, deposited_at: Time.zone.parse('2020-01-15 16:07') }
    let(:work_version) { build_stubbed :work_version,
                                       work: work,
                                       subtitle: 'My subtitle',
                                       keyword: %w(one two),
                                       published_date: nil
    }

    it 'renders a string with label' do
      expect(result.css('th.work-version-subtitle').text).to eq 'Subtitle'
      expect(result.css('td.work-version-subtitle').text).to eq 'My subtitle'
    end

    it 'renders a date with a nice format' do
      expect(result.css('td.work-version-deposited-at').text).to eq 'January 15, 2020 16:07'
    end

    it 'renders a multi-value field' do
      expect(result.css('td.work-version-keyword li.multiple-member').map(&:text))
        .to contain_exactly('one', 'two')
    end

    it 'makes any url in the related_url field clickable' do
      work_version.related_url = [
        'http://psu.edu',
        'not a link'
      ]

      related_urls = result.css('td.work-version-related-url .multiple-member').children

      related_urls[0].tap do |link|
        expect(link['href']).to eq 'http://psu.edu'
        expect(link['target']).to eq '_blank'
        expect(link.text).to eq 'http://psu.edu'
      end

      expect(related_urls[1]).to be_text
    end

    it 'does not render any fields that are empty' do
      expect(result.css('td.work-version-published-date')).to be_empty
    end

    it 'accepts a decorated and non-decorated Work Version' do
      non_decorated_result = render_inline(described_class.new(work_version: work_version))
      expect(non_decorated_result.css('th.work-version-subtitle')).to be_present

      decorated_result = render_inline(described_class.new(work_version: ResourceDecorator.new(work_version)))
      expect(decorated_result.css('th.work-version-subtitle')).to be_present
    end
  end

  describe 'fully loaded' do
    let(:work_version) { build_stubbed :work_version, :with_complete_metadata, :with_creators }

    it 'renders every field' do
      # Titles
      expect(result.css('th.work-version-title')).to be_present
      expect(result.css('th.work-version-subtitle')).to be_present
      expect(result.css('th.work-version-visibility-badge')).to be_present
      expect(result.css('th.work-version-version-number')).to be_present
      expect(result.css('th.work-version-keyword')).to be_present
      expect(result.css('th.work-version-display-rights')).to be_present
      expect(result.css('th.work-version-resource-type')).not_to be_present
      expect(result.css('th.work-version-display-work-type')).to be_present
      expect(result.css('th.work-version-contributor')).to be_present
      expect(result.css('th.work-version-publisher')).to be_present
      expect(result.css('th.work-version-display-published-date')).to be_present
      expect(result.css('th.work-version-subject')).to be_present
      expect(result.css('th.work-version-language')).to be_present
      expect(result.css('th.work-version-identifier')).to be_present
      expect(result.css('th.work-version-based-near')).to be_present
      expect(result.css('th.work-version-related-url')).to be_present
      expect(result.css('th.work-version-source')).to be_present
      expect(result.css('th.work-version-deposited-at')).to be_present
      expect(result.css('th.work-version-creators')).to be_present

      # Test that the fields have the correct values. Please note that some of
      # the more exotic field type (multiples, dates, iso8601 strings) are only
      # rudimentarily tested here, because they're unit-tested in detail above.
      expect(result.css('td.work-version-title').text).to eq work_version[:title]
      expect(result.css('td.work-version-subtitle').text).to eq work_version[:subtitle]
      expect(result.css('td.work-version-creators').text).to include work_version.creators.map(&:display_name).first
      expect(result.css('td.work-version-version-number').text).to eq work_version[:version_number].to_s
      expect(result.css('td.work-version-keyword').text).to include work_version[:keyword].first
      expect(result.css('td.work-version-display-rights a').attr('href').text).to eq work_version[:rights]
      expect(result.css('td.work-version-display-work-type').text).to eq decorated_work_version.display_work_type
      expect(result.css('td.work-version-contributor').text).to include work_version[:contributor].first
      expect(result.css('td.work-version-publisher').text).to include work_version[:publisher].first
      expect(result.css('td.work-version-display-published-date').text)
        .to include Time.zone.parse(work_version[:published_date]).year.to_s
      expect(result.css('td.work-version-subject').text).to include work_version[:subject].first
      expect(result.css('td.work-version-language').text).to include work_version[:language].first
      expect(result.css('td.work-version-identifier').text).to include work_version[:identifier].first
      expect(result.css('td.work-version-based-near').text).to include work_version[:based_near].first
      expect(result.css('td.work-version-related-url').text).to include work_version[:related_url].first
      expect(result.css('td.work-version-source').text).to include work_version[:source].first
      expect(result.css('td.work-version-deposited-at').text).to include work_version.deposited_at.year.to_s
    end

    context 'when mini: true' do
      let(:result) { render_inline(described_class.new(work_version: work_version, mini: true)) }

      it 'renders just the mini fields' do
        # Titles
        expect(result.css('th.work-version-title')).not_to be_present
        expect(result.css('th.work-version-deposited-at')).to be_present
        expect(result.css('th.work-version-creators')).not_to be_present
        expect(result.css('th.work-version-first-creators')).to be_present
        expect(result.css('th.work-version-subtitle')).not_to be_present
        expect(result.css('th.work-version-version-number')).not_to be_present
        expect(result.css('th.work-version-keyword')).not_to be_present
        expect(result.css('th.work-version-rights')).not_to be_present
        expect(result.css('th.work-version-display-work-type')).not_to be_present
        expect(result.css('th.work-version-resource-type')).not_to be_present
        expect(result.css('th.work-version-work-type')).not_to be_present
        expect(result.css('th.work-version-contributor')).not_to be_present
        expect(result.css('th.work-version-publisher')).not_to be_present
        expect(result.css('th.work-version-display-published-date')).not_to be_present
        expect(result.css('th.work-version-subject')).not_to be_present
        expect(result.css('th.work-version-language')).not_to be_present
        expect(result.css('th.work-version-identifier')).not_to be_present
        expect(result.css('th.work-version-based-near')).not_to be_present
        expect(result.css('th.work-version-related-url')).not_to be_present
        expect(result.css('th.work-version-source')).not_to be_present
      end
    end
  end
end
