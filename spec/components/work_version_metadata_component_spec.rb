# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersionMetadataComponent, type: :component do
  let(:result) { render_inline(described_class, work_version: work_version) }

  describe 'rendering' do
    let(:work_version) { WorkVersion.new(
      subtitle: 'My subtitle',
      created_at: Time.zone.parse('2020-01-15 16:07'),
      keywords: %w(one two),
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
      expect(result.css('dd.work-version-keywords .multiple-member').map(&:text))
        .to contain_exactly('one', 'two')

      expect(result.css('dd.work-version-keywords').text).to include('; ')
    end

    it 'does not render any fields that are empty' do
      expect(result.css('dd.work-version-description')).to be_empty
    end
  end
end
