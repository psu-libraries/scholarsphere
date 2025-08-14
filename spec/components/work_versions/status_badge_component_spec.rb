# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersions::StatusBadgeComponent, type: :component do
  let(:node) { render_inline(described_class.new(work_version: work_version)) }
  let(:badge) { node.css('div').first }

  let(:common_expected_classes) { %w(badge badge--nudge-up ms-1) }

  context 'with a draft' do
    let(:work_version) { build_stubbed(:work_version, :draft) }

    specify do
      expect(badge.text).to include('draft')
      expect(badge.classes).to contain_exactly(
        *common_expected_classes,
        'badge--dark-blue', 'badge--outline'
      )
    end

    context 'when inverted' do
      let(:node) { render_inline(described_class.new(work_version: work_version, invert: true)) }

      specify do
        expect(badge.classes).to contain_exactly(
          *common_expected_classes,
          'badge-light', 'badge--outline'
        )
      end
    end
  end

  context 'with a published version' do
    let(:work_version) { create(:work_version, :published, version_number: 3) }

    specify do
      expect(badge.text).to include('published')
      expect(badge.classes).to contain_exactly(
        *common_expected_classes,
        'badge--dark-blue'
      )
    end

    context 'when inverted' do
      let(:node) { render_inline(described_class.new(work_version: work_version, invert: true)) }

      specify do
        expect(badge.classes).to contain_exactly(
          *common_expected_classes,
          'badge-light'
        )
      end
    end
  end

  context 'with a withdrawn version' do
    let(:work_version) { create(:work_version, :withdrawn, version_number: 3) }

    specify do
      expect(badge.text).to include('withdrawn')
      expect(badge.classes).to contain_exactly(
        *common_expected_classes,
        'badge--dark-red'
      )
    end

    context 'when inverted' do
      let(:node) { render_inline(described_class.new(work_version: work_version, invert: true)) }

      specify do
        expect(badge.classes).to contain_exactly(
          *common_expected_classes,
          'badge--light-red'
        )
      end
    end
  end
end
