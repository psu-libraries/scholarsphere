# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersionPolicy, type: :policy do
  subject { described_class }

  let(:work) { instance_double 'Work' }
  let(:work_version) { instance_double 'WorkVersion', work: work }
  let(:user) { instance_double 'User', admin?: false }
  let(:work_policy) { instance_double 'WorkPolicy' }

  permissions :show? do
    it { is_expected.to permit(user, work_version) }
  end

  permissions :diff? do
    before { allow(Pundit).to receive(:policy).with(user, work).and_return(work_policy) }

    context 'when the record is published and not editable' do
      before do
        allow(work_version).to receive(:published?).and_return(true)
        allow(work_policy).to receive(:edit?).and_return(false)
      end

      it { is_expected.to permit(user, work_version) }
    end

    context 'when the record is not published and is editable' do
      before do
        allow(work_version).to receive(:published?).and_return(false)
        allow(work_policy).to receive(:edit?).and_return(true)
      end

      it { is_expected.to permit(user, work_version) }
    end

    context 'when the record is not published and not editable' do
      before do
        allow(work_version).to receive(:published?).and_return(false)
        allow(work_policy).to receive(:edit?).and_return(false)
      end

      it { is_expected.not_to permit(user, work_version) }
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

      context 'with an external application' do
        let(:user) { build(:external_app) }

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
    let(:application) { build(:external_app) }

    context 'with a draft version' do
      let(:work) do
        create(:work, has_draft: true, proxy_depositor: proxy.actor, edit_users: [edit_user])
      end

      it { is_expected.to permit(work.depositor.user, work_version) }
      it { is_expected.to permit(proxy, work_version) }
      it { is_expected.to permit(edit_user, work_version) }
      it { is_expected.not_to permit(other, work_version) }
      it { is_expected.to permit(admin, work_version) }
      it { is_expected.to permit(application, work_version) }
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
      it { is_expected.not_to permit(application, work_version) }
    end
  end

  permissions :destroy? do
    let(:work_version) { work.latest_version }
    let(:proxy) { build(:user) }
    let(:edit_user) { build(:user) }
    let(:other) { build(:user) }
    let(:admin) { build(:user, :admin) }
    let(:application) { build(:external_app) }

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
      it { is_expected.not_to permit(application, work_version) }
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
      it { is_expected.to permit(application, work_version) }
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
      it { is_expected.to permit(application, work_version) }
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
      it { is_expected.not_to permit(application, work_version) }
    end
  end

  permissions :navigable? do
    let(:depositor) { work_version.depositor.user }
    let(:proxy) { build(:user) }
    let(:edit_user) { build(:user) }
    let(:other) { build(:user) }
    let(:admin) { build(:user, :admin) }
    let(:application) { build(:external_app) }
    let(:guest) { User.guest }

    let(:work_version) { work.latest_version }

    context 'when the version is published' do
      let(:work) { create(:work, has_draft: false, proxy_depositor: proxy.actor, edit_users: [edit_user]) }

      it { is_expected.to permit(depositor, work_version) }
      it { is_expected.to permit(proxy, work_version) }
      it { is_expected.to permit(edit_user, work_version) }
      it { is_expected.to permit(other, work_version) }
      it { is_expected.to permit(admin, work_version) }
      it { is_expected.to permit(application, work_version) }
      it { is_expected.to permit(guest, work_version) }
    end

    context 'when the version is draft' do
      let(:work) { create(:work, has_draft: true, proxy_depositor: proxy.actor, edit_users: [edit_user]) }

      it { is_expected.to permit(depositor, work_version) }
      it { is_expected.to permit(proxy, work_version) }
      it { is_expected.to permit(edit_user, work_version) }
      it { is_expected.to permit(admin, work_version) }
      it { is_expected.to permit(application, work_version) }
      it { is_expected.not_to permit(other, work_version) }
      it { is_expected.not_to permit(guest, work_version) }
    end
  end

  permissions :download? do
    let(:depositor) { work_version.depositor.user }
    let(:proxy) { build(:user) }
    let(:edit_user) { build(:user) }
    let(:other) { build(:user) }
    let(:admin) { build(:user, :admin) }
    let(:application) { build(:external_app) }
    let(:guest) { User.guest }

    let(:work_version) { work.latest_version }

    context 'with a published, publicly readable work' do
      let(:work) { create(:work, has_draft: false, proxy_depositor: proxy.actor, edit_users: [edit_user]) }

      it { is_expected.to permit(depositor, work_version) }
      it { is_expected.to permit(proxy, work_version) }
      it { is_expected.to permit(edit_user, work_version) }
      it { is_expected.to permit(other, work_version) }
      it { is_expected.to permit(admin, work_version) }
      it { is_expected.to permit(application, work_version) }
      it { is_expected.to permit(guest, work_version) }
    end

    context 'with a publicly discoverable work' do
      let(:work) { create(:work, :with_authorized_access, has_draft: false, discover_groups: [Group.public_agent]) }

      it { is_expected.to permit(depositor, work_version) }
      it { is_expected.to permit(proxy, work_version) }
      it { is_expected.to permit(edit_user, work_version) }
      it { is_expected.to permit(other, work_version) }
      it { is_expected.to permit(admin, work_version) }
      it { is_expected.to permit(application, work_version) }
      it { is_expected.not_to permit(guest, work_version) }
    end

    context 'with a Penn State work' do
      let(:work) { create(:work, :with_authorized_access, has_draft: false) }

      it { is_expected.to permit(depositor, work_version) }
      it { is_expected.to permit(proxy, work_version) }
      it { is_expected.to permit(edit_user, work_version) }
      it { is_expected.to permit(other, work_version) }
      it { is_expected.to permit(admin, work_version) }
      it { is_expected.to permit(application, work_version) }
      it { is_expected.not_to permit(guest, work_version) }
    end

    context 'with an embargoed public work' do
      let(:work) do
        create :work,
               has_draft: false,
               embargoed_until: (Time.zone.now + 6.days),
               edit_users: [edit_user],
               proxy_depositor: proxy.actor
      end

      it { is_expected.to permit(depositor, work_version) }
      it { is_expected.to permit(proxy, work_version) }
      it { is_expected.to permit(edit_user, work_version) }
      it { is_expected.not_to permit(other, work_version) }
      it { is_expected.to permit(admin, work_version) }
      it { is_expected.to permit(application, work_version) }
      it { is_expected.not_to permit(guest, work_version) }
    end

    context 'with a draft work' do
      let(:work) { create(:work, proxy_depositor: proxy.actor, edit_users: [edit_user]) }

      it { is_expected.to permit(depositor, work_version) }
      it { is_expected.to permit(proxy, work_version) }
      it { is_expected.to permit(edit_user, work_version) }
      it { is_expected.not_to permit(other, work_version) }
      it { is_expected.to permit(admin, work_version) }
      it { is_expected.to permit(application, work_version) }
      it { is_expected.not_to permit(guest, work_version) }
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
