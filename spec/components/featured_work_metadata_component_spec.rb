# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeaturedWorkMetadataComponent, type: :component do
  let(:decorated_work_version) { ResourceDecorator.new(work_version) }
  let(:result) { render_inline(described_class.new(work_version: decorated_work_version)) }

  describe 'rendering' do
    let(:work_version) { build_stubbed :work_version, :with_complete_metadata, :with_creators }

    it 'renders creators' do
      expect(result.css('dt.creator_aliases').text).to eq 'Creator'
      expect(result.css('dd.creator_aliases').text).to eq work_version.creator_aliases.first.alias
    end

    it 'renders keywords' do
      expect(result.css('dt.keyword').text).to eq 'Keywords'
      expect(result.css('dd.keyword').text).to eq work_version.keyword.first
    end
  end
end
