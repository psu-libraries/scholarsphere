# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::WorkVersionPolicy, type: :policy do
  subject { described_class }

  let(:deposited_work_version) { instance_double('WorkVersion', depositor: user_actor, proxy_depositor: nil) }
  let(:proxy_deposited_work_version) { instance_double('WorkVersion', depositor: other_actor, proxy_depositor: user_actor) }

  let(:user) { instance_double('User', 'depositor user', actor: user_actor) }
  let(:user_actor) { instance_double('Actor', 'depositor actor') }

  let(:other_user) { instance_double('User', 'another user', actor: other_actor) }
  let(:other_actor) { instance_double('Actor', 'another actor') }

  it_behaves_like 'a downloadable work version'

  permissions '.scope' do
    let(:scoped_versions) { described_class::Scope.new(user, WorkVersion).resolve }

    let(:user) { create(:user) }
    let(:user_actor) { user.actor }

    let!(:deposited_work_version) { create :work_version, title: 'My Deposited Work' }
    let!(:proxied_work_version) { create :work_version, title: 'My Proxy Deposited Work' }

    before do
      deposited_work_version.work.update!(depositor: user_actor)
      proxied_work_version.work.update!(proxy_depositor: user_actor)

      create :work_version, title: "Other User's Version"
    end

    it 'only finds my work versions' do
      expect(scoped_versions.map(&:title)).to include('My Deposited Work')
        .and include('My Proxy Deposited Work')
      expect(scoped_versions.map(&:title)).not_to include("Other User's Version")
    end
  end

  permissions :show? do
    it { is_expected.to permit(user, deposited_work_version) }
    it { is_expected.to permit(user, proxy_deposited_work_version) }
    it { is_expected.not_to permit(other_user, deposited_work_version) }
  end

  permissions :edit?, :update?, :destroy?, :publish? do
    context 'when work version is draft' do
      before do
        allow(deposited_work_version).to receive(:draft?).and_return(true)
        allow(proxy_deposited_work_version).to receive(:draft?).and_return(true)
      end

      it { is_expected.to permit(user, deposited_work_version) }
      it { is_expected.to permit(user, proxy_deposited_work_version) }
      it { is_expected.not_to permit(other_user, deposited_work_version) }
    end

    context 'when work version is published' do
      before do
        allow(deposited_work_version).to receive(:draft?).and_return(false)
        allow(proxy_deposited_work_version).to receive(:draft?).and_return(false)
      end

      it { is_expected.not_to permit(user, deposited_work_version) }
      it { is_expected.not_to permit(user, proxy_deposited_work_version) }
      it { is_expected.not_to permit(other_user, deposited_work_version) }
    end
  end

  describe '#new?' do
    subject(:new) { policy.new?(latest_version) }

    let(:policy) { described_class.new(user, deposited_work_version) }
    let(:latest_version) { deposited_work_version }

    context 'when the version is published' do
      before { allow(deposited_work_version).to receive(:published?).and_return(true) }

      context 'when the version is the latest one in the work' do
        let(:latest_version) { deposited_work_version }

        it { is_expected.to eq true }
      end

      context 'when the version is NOT the latest one in the work' do
        let(:latest_version) { instance_double('WorkVersion') }

        it { is_expected.to eq false }
      end
    end

    context 'when the version is NOT published' do
      before { allow(deposited_work_version).to receive(:published?).and_return(false) }

      it { is_expected.to eq false }
    end
  end
end
