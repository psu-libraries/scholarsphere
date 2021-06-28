# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersionDetailComponent, type: :component do
  subject(:content) { render_inline(described_class.new(work_version: work_version)).to_s }

  let(:work) { build_stubbed(:work) }
  let(:work_version) { build_stubbed(:work_version, work: work) }
  let(:representative_version) { build_stubbed(:work_version, work: work) }

  before do
    allow(work).to receive(:representative_version).and_return(representative_version)
  end

  context 'when the work version is draft state' do
    before { allow(work_version).to receive(:draft?).and_return(true) }

    context 'with no other existing versions' do
      let(:representative_version) { work_version }

      it { is_expected.to include('This is a draft version of the work') }
      it { is_expected.not_to include(work.uuid) }
    end

    context 'with other versions available' do
      it { is_expected.to include('This is a draft version of the work') }
      it { is_expected.to include(work.uuid) }
    end
  end

  context 'when the work version is NOT in draft state' do
    before { allow(work_version).to receive(:draft?).and_return(false) }

    context 'with no other existing versions' do
      let(:representative_version) { work_version }

      it { is_expected.to be_empty }
    end

    context 'with newer versions available' do
      it { is_expected.to include('This is an older version of the work') }
      it { is_expected.to include(work.uuid) }
    end
  end
end
