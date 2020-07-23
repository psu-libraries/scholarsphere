# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersions::StatusBadgeComponent, type: :component do
  let(:node) { render_inline(described_class.new(work_version: work_version)) }
  let(:badge) { node.css('div').first }

  context 'with a draft' do
    let(:work_version) { build_stubbed :work_version, :draft }

    specify do
      expect(badge.text).to include('draft')
      expect(badge.attributes['data-before'].value).to eq('V1')
      expect(badge.classes).to contain_exactly('badge', 'badge--text', 'badge--gray-800')
    end
  end

  context 'with a published version' do
    let(:work_version) { build_stubbed :work_version, :published, version_number: 3 }

    specify do
      expect(badge.text).to include('published')
      expect(badge.attributes['data-before'].value).to eq('V3')
      expect(badge.classes).to contain_exactly('badge', 'badge--text', 'badge--dark-blue')
    end
  end
end
