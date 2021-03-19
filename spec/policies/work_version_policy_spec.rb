# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersionPolicy, type: :policy do
  subject { described_class }

  let(:work) { instance_double 'Work' }
  let(:work_version) { instance_double 'WorkVersion', work: work }
  let(:user) { instance_double 'User', admin?: false }
  let(:work_policy) { instance_double 'WorkPolicy' }

  permissions :show?, :diff? do
    before { allow(Pundit).to receive(:policy).with(user, work).and_return(work_policy) }

    context 'when the user has show access to the work' do
      before { allow(work_policy).to receive(:show?).and_return(true) }

      it { is_expected.to permit(user, work_version) }
    end

    context 'when the user has NO show access to the work' do
      context 'when the user has edit access to the work' do
        before do
          allow(work_policy).to receive(:show?).and_return(false)
          allow(work_policy).to receive(:edit?).and_return(true)
        end

        it { is_expected.to permit(user, work_version) }
      end

      context 'when the user has NO edit access to the work' do
        before do
          allow(work_policy).to receive(:show?).and_return(false)
          allow(work_policy).to receive(:edit?).and_return(false)
        end

        it { is_expected.not_to permit(user, work_version) }
      end
    end
  end

  permissions :edit?, :update? do
    before { allow(Pundit).to receive(:policy).with(user, work).and_return(work_policy) }

    context 'when the version is NOT published' do
      before { allow(work_version).to receive(:published?).and_return(false) }

      context 'when the user has the access to the work' do
        before { allow(work_policy).to receive(:edit?).and_return(true) }

        it { is_expected.to permit(user, work_version) }
      end

      context 'when the user does NOT have the access to the work' do
        before { allow(work_policy).to receive(:edit?).and_return(false) }

        it { is_expected.not_to permit(user, work_version) }
      end
    end

    context 'when the version is published' do
      before do
        allow(work_version).to receive(:published?).and_return(true)
        allow(work_policy).to receive(:edit?).and_return(true)
      end

      context 'when the user has the access to the work' do
        it { is_expected.not_to permit(user, work_version) }
      end

      context 'when the user is an admin' do
        let(:user) { build(:user, :admin) }

        it { is_expected.to permit(user, work_version) }
      end
    end
  end

  permissions :publish? do
    let(:work_version) { work.latest_version }
    let(:proxy) { build(:user) }
    let(:edit_user) { build(:user) }
    let(:other) { build(:user) }
    let(:admin) { build(:user, :admin) }

    context 'with a draft version' do
      let(:work) do
        create(:work, has_draft: true, proxy_depositor: proxy.actor, edit_users: [edit_user])
      end

      it { is_expected.to permit(work.depositor.user, work_version) }
      it { is_expected.to permit(proxy, work_version) }
      it { is_expected.to permit(edit_user, work_version) }
      it { is_expected.not_to permit(other, work_version) }
      it { is_expected.to permit(admin, work_version) }
    end

    context 'with a published version' do
      let(:work) do
        create(:work, has_draft: false, proxy_depositor: proxy.actor, edit_users: [edit_user])
      end

      it { is_expected.not_to permit(work.depositor.user, work_version) }
      it { is_expected.not_to permit(proxy, work_version) }
      it { is_expected.not_to permit(edit_user, work_version) }
      it { is_expected.not_to permit(other, work_version) }
      it { is_expected.not_to permit(admin, work_version) }
    end
  end

  permissions :destroy? do
    let(:work_version) { work.latest_version }
    let(:proxy) { build(:user) }
    let(:edit_user) { build(:user) }
    let(:other) { build(:user) }
    let(:admin) { build(:user, :admin) }

    context 'with a draft version that has NOT been persisted' do
      let(:work) do
        build(:work, has_draft: true, proxy_depositor: proxy.actor, edit_users: [edit_user])
      end

      it 'sanity checks the test environment' do
        expect(work_version).not_to be_persisted
      end

      it { is_expected.not_to permit(work.depositor.user, work_version) }
      it { is_expected.not_to permit(proxy, work_version) }
      it { is_expected.not_to permit(edit_user, work_version) }
      it { is_expected.not_to permit(other, work_version) }
      it { is_expected.not_to permit(admin, work_version) }
    end

    context 'with a draft version' do
      let(:work) do
        create(:work, has_draft: true, proxy_depositor: proxy.actor, edit_users: [edit_user])
      end

      it { is_expected.to permit(work.depositor.user, work_version) }
      it { is_expected.to permit(proxy, work_version) }
      it { is_expected.to permit(edit_user, work_version) }
      it { is_expected.not_to permit(other, work_version) }
      it { is_expected.to permit(admin, work_version) }
    end

    context 'with the latest published version' do
      let(:work) do
        create(:work, has_draft: false, proxy_depositor: proxy.actor, edit_users: [edit_user])
      end

      it { is_expected.not_to permit(work.depositor.user, work_version) }
      it { is_expected.not_to permit(proxy, work_version) }
      it { is_expected.not_to permit(edit_user, work_version) }
      it { is_expected.not_to permit(other, work_version) }
      it { is_expected.to permit(admin, work_version) }
    end

    context 'with a published version that is NOT the latest' do
      let(:work) do
        create(:work, versions_count: 2, proxy_depositor: proxy.actor, edit_users: [edit_user])
      end

      let(:work_version) { work.versions.first }

      it { is_expected.not_to permit(work.depositor.user, work_version) }
      it { is_expected.not_to permit(proxy, work_version) }
      it { is_expected.not_to permit(edit_user, work_version) }
      it { is_expected.not_to permit(other, work_version) }
      it { is_expected.not_to permit(admin, work_version) }
    end
  end

  permissions :download? do
    let(:work_version) { work.latest_version }

    context 'with a public user' do
      let(:user) { User.guest }

      context 'with a published, publicly readable work' do
        let(:work) { create(:work, has_draft: false) }

        it { is_expected.to permit(user, work_version) }
      end

      context 'with a publicly discoverable work' do
        let(:work) { create(:work, :with_authorized_access, discover_groups: [Group.public_agent]) }

        it { is_expected.not_to permit(user, work_version) }
      end

      context 'with a Penn State work' do
        let(:work) { create(:work, :with_authorized_access, has_draft: false) }

        it { is_expected.not_to permit(user, work_version) }
      end

      context 'with an embargoed public work' do
        let(:work) { create(:work, embargoed_until: (Time.zone.now + 6.days), has_draft: false) }

        it { is_expected.not_to permit(user, work_version) }
      end

      context 'with a draft work' do
        let(:work) { create(:work, has_draft: true) }

        it { is_expected.not_to permit(user, work_version) }
      end
    end

    context 'with an authenticated user' do
      let(:me) { build(:user) }
      let(:someone_else) { build(:user) }

      context 'with a published, publicly readable work' do
        let(:work) { create(:work, has_draft: false, depositor: someone_else.actor) }

        it { is_expected.to permit(me, work_version) }
      end

      context 'with a Penn State work' do
        let(:work) { create(:work, :with_authorized_access, has_draft: false, depositor: someone_else.actor) }

        it { is_expected.to permit(me, work_version) }
      end

      context 'with a draft version I deposited' do
        let(:work) { create(:work, depositor: me.actor) }

        it { is_expected.to permit(me, work_version) }
      end

      context 'with a draft version I did NOT deposit' do
        let(:work) { build(:work, depositor: someone_else.actor) }

        it { is_expected.not_to permit(me, work_version) }
      end

      context 'with an embargoed public work' do
        let(:work) { create(:work, has_draft: false, depositor: someone_else.actor, embargoed_until: (Time.zone.now + 6.days)) }

        it { is_expected.not_to permit(me, work_version) }
      end

      context 'with an embargoed work I deposited' do
        let(:work) { create(:work, has_draft: false, depositor: me.actor, embargoed_until: (Time.zone.now + 6.days)) }

        it { is_expected.to permit(me, work_version) }
      end

      context 'with an embargoed work editable by me' do
        let(:work) do
          create :work,
                 has_draft: false,
                 depositor: someone_else.actor,
                 embargoed_until: (Time.zone.now + 6.days),
                 edit_users: [me]
        end

        it { is_expected.to permit(me, work_version) }
      end
    end
  end

  permissions :new? do
    before { allow(Pundit).to receive(:policy).with(user, work).and_return(work_policy) }

    context 'when the parent work is elligible to create a new version' do
      before { allow(work_policy).to receive(:create_version?).and_return(true) }

      context 'when the given work version is the latest published version' do
        before { allow(work).to receive(:latest_published_version).and_return(work_version) }

        it { is_expected.to permit(user, work_version) }
      end

      context 'when the given work version is NOT the latest published version' do
        before { allow(work).to receive(:latest_published_version).and_return(instance_double('WorkVersion')) }

        it { is_expected.not_to permit(user, work_version) }
      end
    end

    context 'when the parent work cannot create a new version' do
      before { allow(work_policy).to receive(:create_version?).and_return(false) }

      context 'when the given work version is the latest published version' do
        before { allow(work).to receive(:latest_published_version).and_return(work_version) }

        it { is_expected.not_to permit(user, work_version) }
      end

      context 'when the given work version is NOT the latest published version' do
        before { allow(work).to receive(:latest_published_version).and_return(instance_double('WorkVersion')) }

        it { is_expected.not_to permit(user, work_version) }
      end
    end
  end
end
