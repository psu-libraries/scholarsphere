# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersions::StatusBadgeComponent, type: :component do
  subject { render_inline(described_class.new(work_version: work_version)).to_html.strip }

  context 'with a draft' do
    let(:work_version) { build_stubbed :work_version, :draft }

    it { is_expected.to eq '<span class="badge version-status version-status--draft">draft</span>' }
  end

  context 'with a published version' do
    let(:work_version) { build_stubbed :work_version, :published }

    it { is_expected.to eq '<span class="badge version-status version-status--published">published</span>' }
  end
end
