# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersionMetadataComponent, type: :component do
  let(:result) { render_inline(described_class, work_version: work_version) }

  describe 'rendering' do
    let(:work_version) { WorkVersion.new(
      subtitle: 'My subtitle',
      created_at: Time.zone.parse('2020-01-15 16:07'),
      keyword: %w(one two),
      description: nil
    ) }

    it 'renders a string with label' do
      expect(result.css('dt.work-version-subtitle').text).to eq 'Subtitle'
      expect(result.css('dd.work-version-subtitle').text).to eq 'My subtitle'
    end

    it 'renders a date with a nice format' do
      expect(result.css('dd.work-version-created-at').text).to eq 'January 15, 2020 16:07'
    end

    it 'renders a multi-value field' do
      expect(result.css('dd.work-version-keyword .multiple-member').map(&:text))
        .to contain_exactly('one', 'two')

      expect(result.css('dd.work-version-keyword').text).to include('; ')
    end

    it 'does not render any fields that are empty' do
      expect(result.css('dd.work-version-description')).to be_empty
    end
  end

  describe 'fully loaded' do
    let(:work_version) { build_stubbed :work_version, :with_complete_metadata, :with_creators }

    it 'renders every field' do
      # Titles
      expect(result.css('dt.work-version-title')).to be_present
      expect(result.css('dt.work-version-subtitle')).to be_present
      expect(result.css('dt.work-version-version-number')).to be_present
      expect(result.css('dt.work-version-description')).to be_present
      expect(result.css('dt.work-version-keyword')).to be_present
      expect(result.css('dt.work-version-rights')).to be_present
      expect(result.css('dt.work-version-resource-type')).to be_present
      expect(result.css('dt.work-version-contributor')).to be_present
      expect(result.css('dt.work-version-publisher')).to be_present
      expect(result.css('dt.work-version-published-date')).to be_present
      expect(result.css('dt.work-version-subject')).to be_present
      expect(result.css('dt.work-version-language')).to be_present
      expect(result.css('dt.work-version-identifier')).to be_present
      expect(result.css('dt.work-version-based-near')).to be_present
      expect(result.css('dt.work-version-related-url')).to be_present
      expect(result.css('dt.work-version-source')).to be_present
      expect(result.css('dt.work-version-created-at')).to be_present
      expect(result.css('dt.work-version-creator-aliases')).to be_present

      # Test that the fields have the correct values. Please note that some of
      # the more exotic field type (multiples, dates, iso8601 strings) are only
      # rudimentarily tested here, because they're unit-tested in detail above.
      expect(result.css('dd.work-version-title').text).to eq work_version[:title]
      expect(result.css('dd.work-version-subtitle').text).to eq work_version[:subtitle]
      expect(result.css('dd.work-version-creator-aliases').text).to include work_version.creator_aliases.map(&:alias).first
      expect(result.css('dd.work-version-version-number').text).to eq work_version[:version_number].to_s
      expect(result.css('dd.work-version-description').text).to include work_version[:description].first
      expect(result.css('dd.work-version-keyword').text).to include work_version[:keyword].first
      expect(result.css('dd.work-version-rights').text).to eq work_version[:rights]
      expect(result.css('dd.work-version-resource-type').text).to include work_version[:resource_type].first
      expect(result.css('dd.work-version-contributor').text).to include work_version[:contributor].first
      expect(result.css('dd.work-version-publisher').text).to include work_version[:publisher].first
      expect(result.css('dd.work-version-published-date').text)
        .to include Time.zone.parse(work_version[:published_date].first).year.to_s
      expect(result.css('dd.work-version-subject').text).to include work_version[:subject].first
      expect(result.css('dd.work-version-language').text).to include work_version[:language].first
      expect(result.css('dd.work-version-identifier').text).to include work_version[:identifier].first
      expect(result.css('dd.work-version-based-near').text).to include work_version[:based_near].first
      expect(result.css('dd.work-version-related-url').text).to include work_version[:related_url].first
      expect(result.css('dd.work-version-source').text).to include work_version[:source].first
      expect(result.css('dd.work-version-created-at').text).to include work_version[:created_at].year.to_s
    end

    context 'when mini: true' do
      let(:result) { render_inline(described_class, work_version: work_version, mini: true) }

      it 'renders just the mini fields' do
        # Titles
        expect(result.css('dt.work-version-title')).to be_present
        expect(result.css('dt.work-version-created-at')).to be_present
        expect(result.css('dt.work-version-creator-aliases')).to be_present
        expect(result.css('dt.work-version-subtitle')).not_to be_present
        expect(result.css('dt.work-version-version-number')).not_to be_present
        expect(result.css('dt.work-version-description')).not_to be_present
        expect(result.css('dt.work-version-keyword')).not_to be_present
        expect(result.css('dt.work-version-rights')).not_to be_present
        expect(result.css('dt.work-version-resource-type')).not_to be_present
        expect(result.css('dt.work-version-contributor')).not_to be_present
        expect(result.css('dt.work-version-publisher')).not_to be_present
        expect(result.css('dt.work-version-published-date')).not_to be_present
        expect(result.css('dt.work-version-subject')).not_to be_present
        expect(result.css('dt.work-version-language')).not_to be_present
        expect(result.css('dt.work-version-identifier')).not_to be_present
        expect(result.css('dt.work-version-based-near')).not_to be_present
        expect(result.css('dt.work-version-related-url')).not_to be_present
        expect(result.css('dt.work-version-source')).not_to be_present
      end
    end
  end
end
