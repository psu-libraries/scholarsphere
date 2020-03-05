# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileVersionMembershipPolicy, type: :policy do
  subject { described_class }

  let(:file_version) { build(:file_version_membership, work_version: work_version) }

  permissions :download? do
    context 'with a public user' do
      let(:user) { User.guest }

      context 'with a published, publicly readable work' do
        let(:work_version) { build(:work_version, :published) }

        it { is_expected.to permit(user, file_version) }
      end

      context 'with a publicly discoverable work' do
        let(:v1) { build(:work_version, :published) }
        let(:work) { create(:work, :with_authorized_access, discover_groups: [Group.public_agent], versions: [v1]) }
        let(:work_version) { work.versions[0] }

        it { is_expected.not_to permit(user, file_version) }
      end

      context 'with a Penn State work' do
        let(:work) { create(:work, :with_authorized_access, has_draft: false) }
        let(:work_version) { work.versions[0] }

        it { is_expected.not_to permit(user, file_version) }
      end

      context 'with an embargoed public work' do
        let(:work) { create(:work, embargoed_until: (DateTime.now + 6.days), has_draft: false) }
        let(:work_version) { work.versions[0] }

        it { is_expected.not_to permit(user, file_version) }
      end

      context 'with a draft work' do
        let(:work_version) { build(:work_version) }

        it { is_expected.not_to permit(user, file_version) }
      end
    end

    context 'with an authenticated user' do
      let(:me) { build(:user) }
      let(:someone_else) { build(:user) }

      context 'with a published, publicly readable work' do
        let(:work) { create(:work, has_draft: false, depositor: someone_else) }
        let(:work_version) { work.versions[0] }

        it { is_expected.to permit(me, file_version) }
      end

      context 'with a Penn State work' do
        let(:work) { create(:work, :with_authorized_access, has_draft: false, depositor: someone_else) }
        let(:work_version) { work.versions[0] }

        it { is_expected.to permit(me, file_version) }
      end

      context 'with a draft version I deposited' do
        let(:work) { create(:work, depositor: me) }
        let(:work_version) { work.versions[0] }

        it { is_expected.to permit(me, file_version) }
      end

      context 'with a draft version I did NOT deposit' do
        let(:work) { build(:work, depositor: someone_else) }
        let(:work_version) { work.versions[0] }

        it { is_expected.not_to permit(me, file_version) }
      end

      context 'with an embargoed public work' do
        let(:work) { create(:work, has_draft: false, depositor: someone_else, embargoed_until: (DateTime.now + 6.days)) }
        let(:work_version) { work.versions[0] }

        it { is_expected.not_to permit(me, file_version) }
      end

      context 'with an embargoed work I deposited' do
        let(:work) { create(:work, has_draft: false, depositor: me, embargoed_until: (DateTime.now + 6.days)) }
        let(:work_version) { work.versions[0] }

        it { is_expected.to permit(me, file_version) }
      end

      context 'with an embargoed work editable by me' do
        let(:work) do
          create :work,
                 has_draft: false,
                 depositor: someone_else,
                 embargoed_until: (DateTime.now + 6.days),
                 edit_users: [me]
        end
        let(:work_version) { work.versions[0] }

        it { is_expected.to permit(me, file_version) }
      end
    end
  end
end
