# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersions::VersionStatusBadgeComponent, type: :component do
  let(:node) { render_inline(described_class.new(work_version: work_version)) }
  let(:badge) { node.css('div').first }

  context 'with a draft' do
    let(:work_version) { build_stubbed(:work_version, :draft, version_number: 1) }

    specify do
      expect(badge.text).to include('draft').and include('V1')
      expect(badge.classes).to contain_exactly('badge', 'badge--text', 'badge--dark-blue', 'badge--outline')
    end
  end

  context 'with a published version' do
    let(:work_version) { create(:work_version, :published, version_number: 3) }

    specify do
      expect(badge.text).to include('published')
        .and include('V3')
      expect(badge.classes).to contain_exactly('badge', 'badge--text', 'badge--dark-blue')
    end
  end

  context 'with a withdrawn version' do
    let(:work_version) { create(:work_version, :withdrawn, version_number: 3) }

    specify do
      expect(badge.text).to include('withdrawn')
        .and include('V3')
      expect(badge.classes).to contain_exactly('badge', 'badge--text', 'badge--dark-red')
    end
  end

  context 'when version_name is provided' do
    let(:work_version) { build_stubbed(:work_version, version_name: '1.2.3') }

    specify do
      expect(badge.text).to include('V1.2.3')
    end
  end
end
