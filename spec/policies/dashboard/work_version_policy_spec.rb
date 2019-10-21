# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::WorkVersionPolicy, type: :policy do
  subject { described_class }

  let(:work_version) { instance_double('WorkVersion', depositor: depositor) }

  let(:depositor) { instance_double('User', 'depositor') }
  let(:other_user) { instance_double('User', 'another user') }

  permissions '.scope' do
    pending "add some examples to (or delete) #{__FILE__}"
  end

  permissions :show? do
    it { is_expected.to permit(depositor, work_version) }
    it { is_expected.not_to permit(other_user, work_version) }
  end

  permissions :edit?, :update?, :delete? do
    context 'when work version is draft' do
      before { allow(work_version).to receive(:draft?).and_return(true) }

      it { is_expected.to permit(depositor, work_version) }
      it { is_expected.not_to permit(other_user, work_version) }
    end

    context 'when work version is published' do
      before { allow(work_version).to receive(:draft?).and_return(false) }

      it { is_expected.not_to permit(depositor, work_version) }
      it { is_expected.not_to permit(other_user, work_version) }
    end
  end

  describe '#new?' do
    subject(:new) { policy.new?(latest_version) }

    let(:policy) { described_class.new(depositor, work_version) }
    let(:latest_version) { work_version }

    context 'when the version is published' do
      before { allow(work_version).to receive(:published?).and_return(true) }

      context 'when the version is the latest one in the work' do
        let(:latest_version) { work_version }

        it { is_expected.to eq true }
      end

      context 'when the version is NOT the latest one in the work' do
        let(:latest_version) { instance_double('WorkVersion') }

        it { is_expected.to eq false }
      end
    end

    context 'when the version is NOT published' do
      before { allow(work_version).to receive(:published?).and_return(false) }

      it { is_expected.to eq false }
    end
  end
end
