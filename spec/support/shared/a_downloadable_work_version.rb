# frozen_string_literal: true

RSpec.shared_examples 'a downloadable work version' do
  permissions :download? do
    context 'with a public user' do
      let(:user) { User.guest }

      context 'with a published, publicly readable work' do
        let(:work_version) { build(:work_version, :published) }

        it { is_expected.to permit(user, work_version) }
      end

      context 'with a publicly discoverable work' do
        let(:v1) { build(:work_version, :published) }
        let(:work) { create(:work, :with_authorized_access, discover_groups: [Group.public_agent], versions: [v1]) }
        let(:work_version) { work.versions[0] }

        it { is_expected.not_to permit(user, work_version) }
      end

      context 'with a Penn State work' do
        let(:work) { create(:work, :with_authorized_access, has_draft: false) }
        let(:work_version) { work.versions[0] }

        it { is_expected.not_to permit(user, work_version) }
      end

      context 'with an embargoed public work' do
        let(:work) { create(:work, embargoed_until: (DateTime.now + 6.days), has_draft: false) }
        let(:work_version) { work.versions[0] }

        it { is_expected.not_to permit(user, work_version) }
      end

      context 'with a draft work' do
        let(:work_version) { build(:work_version) }

        it { is_expected.not_to permit(user, work_version) }
      end
    end

    context 'with an authenticated user' do
      let(:me) { build(:user) }
      let(:someone_else) { build(:user) }

      context 'with a published, publicly readable work' do
        let(:work) { create(:work, has_draft: false, depositor: someone_else.actor) }
        let(:work_version) { work.versions[0] }

        it { is_expected.to permit(me, work_version) }
      end

      context 'with a Penn State work' do
        let(:work) { create(:work, :with_authorized_access, has_draft: false, depositor: someone_else.actor) }
        let(:work_version) { work.versions[0] }

        it { is_expected.to permit(me, work_version) }
      end

      context 'with a draft version I deposited' do
        let(:work) { create(:work, depositor: me.actor) }
        let(:work_version) { work.versions[0] }

        it { is_expected.to permit(me, work_version) }
      end

      context 'with a draft version I did NOT deposit' do
        let(:work) { build(:work, depositor: someone_else.actor) }
        let(:work_version) { work.versions[0] }

        it { is_expected.not_to permit(me, work_version) }
      end

      context 'with an embargoed public work' do
        let(:work) { create(:work, has_draft: false, depositor: someone_else.actor, embargoed_until: (DateTime.now + 6.days)) }
        let(:work_version) { work.versions[0] }

        it { is_expected.not_to permit(me, work_version) }
      end

      context 'with an embargoed work I deposited' do
        let(:work) { create(:work, has_draft: false, depositor: me.actor, embargoed_until: (DateTime.now + 6.days)) }
        let(:work_version) { work.versions[0] }

        it { is_expected.to permit(me, work_version) }
      end

      context 'with an embargoed work editable by me' do
        let(:work) do
          create :work,
                 has_draft: false,
                 depositor: someone_else.actor,
                 embargoed_until: (DateTime.now + 6.days),
                 edit_users: [me]
        end
        let(:work_version) { work.versions[0] }

        it { is_expected.to permit(me, work_version) }
      end
    end
  end
end
