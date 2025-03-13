# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeaturedWorkMetadataComponent, type: :component do
  let(:decorated_work_version) { ResourceDecorator.new(work_version) }
  let(:result) { render_inline(described_class.new(work_version: decorated_work_version)) }

  describe 'rendering' do
    let(:work_version) { build_stubbed(:work_version, :with_complete_metadata, :with_creators) }

    it 'renders creators' do
      expect(result.css('dt.creators').text).to eq WorkVersion.human_attribute_name(:creators)
      expect(result.css('dd.creators').text).to eq work_version.creators.first.display_name
    end
  end
end
