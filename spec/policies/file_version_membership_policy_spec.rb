# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileVersionMembershipPolicy, type: :policy do
  subject { described_class }

  let(:user) { instance_double 'User' }
  let(:file_version_membership) { instance_double 'FileVersionMembership', work_version: work_version }
  let(:work_version) { instance_double 'WorkVersion' }
  let(:mock_policy) { instance_spy 'WorkVersionPolicy' }
  let(:admin) { build(:user, :admin) }

  describe 'download?' do
    before { allow(Pundit).to receive(:policy).with(user, work_version).and_return(mock_policy) }

    it 'delegates to WorkVersionPolicy#download?' do
      described_class.new(user, file_version_membership).download?
      expect(mock_policy).to have_received(:download?)
    end
  end

  permissions :destroy? do
    let(:regular_user) { build(:user) }
    let(:edit_user) { build(:user) }
    let(:proxy_user) { build(:user) }
    let(:admin) { build(:user, :admin) }
    let(:application) { build(:external_app) }
    let (:work) { create(:work, proxy_depositor: proxy_user.actor, edit_users: [edit_user]) }
    let(:work_version) { create(:work_version, :draft, work:) }

    context 'with a draft version that has NOT been persisted' do
      let(:membership) { build(:file_version_membership) }

      it { is_expected.not_to permit(regular_user, membership) }
      it { is_expected.not_to permit(proxy_user, membership) }
      it { is_expected.not_to permit(edit_user, membership) }
      it { is_expected.not_to permit(admin, membership) }
      it { is_expected.not_to permit(application, membership) }
    end

    context 'with the latest draft version' do
      let(:membership) { create(:file_version_membership, work_version:) }

      it { is_expected.not_to permit(regular_user, membership) }
      it { is_expected.to permit(proxy_user, membership) }
      it { is_expected.to permit(edit_user, membership) }
      it { is_expected.to permit(admin, membership) }
      it { is_expected.to permit(application, membership) }
    end

    context 'with a draft version that is NOT the latest' do
      let(:work) { create(:work, versions_count: 2, proxy_depositor: proxy_user.actor, edit_users: [edit_user]) }
      let (:work_version) { create(:work_version, work:) }
      let(:membership) { create(:file_version_membership, work_version:) }

      it { is_expected.not_to permit(regular_user, membership) }
      it { is_expected.to permit(proxy_user, membership) }
      it { is_expected.to permit(edit_user, membership) }
      it { is_expected.to permit(application, membership) }
      it { is_expected.to permit(admin, membership) }
    end

    context 'with a published version' do
      let (:work_version) { create(:work_version, :published, work:) }
      let(:membership) { create(:file_version_membership, work_version:) }

      it { is_expected.not_to permit(regular_user, membership) }
      it { is_expected.not_to permit(edit_user, membership) }
      it { is_expected.not_to permit(proxy_user, membership) }
      it { is_expected.to permit(admin, membership) }
      it { is_expected.to permit(application, membership) }
    end
  end
end
