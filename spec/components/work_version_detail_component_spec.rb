# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersionDetailComponent, type: :component do
  subject(:content) { render_inline(described_class.new(work_version: work_version)).to_s }

  let(:work) { build_stubbed(:work) }
  let(:work_version) { build_stubbed(:work_version, work: work) }
  let(:user) { build_stubbed(:user) }
  let(:controller_name) { 'application' }
  let(:mock_controller) do
    instance_double('ApplicationController', current_user: user, controller_name: controller_name)
  end

  before do
    allow_any_instance_of(described_class).to receive(:controller).and_return(mock_controller)
  end

  context 'when a current (editable) draft version exists' do
    let(:user) { work.depositor.user }

    context 'when the work version is the current draft version' do
      before { allow(work).to receive(:draft_version).and_return(work_version) }

      it { is_expected.to be_empty }
    end

    context 'when another version is the draft version' do
      let(:other_version) { build_stubbed(:work_version) }

      before { allow(work).to receive(:draft_version).and_return(other_version) }

      it { is_expected.to include('An updated draft version for this work is available') }
      it { is_expected.to include(other_version.uuid) }
    end
  end

  context 'when a current (editable) draft version does NOT exist' do
    context 'when the work version is the current draft version' do
      before { allow(work).to receive(:draft_version).and_return(work_version) }

      it { is_expected.to be_empty }
    end

    context 'when the work version is the current published version' do
      before do
        allow(work).to receive(:representative_version).and_return(work_version)
        allow(work_version).to receive(:published?).and_return(true)
      end

      it { is_expected.to be_empty }
    end

    context 'when another version is the current published version' do
      let(:other_version) { build_stubbed(:work_version) }

      before do
        allow(work).to receive(:representative_version).and_return(other_version)
        allow(other_version).to receive(:published?).and_return(true)
      end

      it { is_expected.to include('This is an older version of the work') }
      it { is_expected.to include(work.uuid) }
    end
  end
end
