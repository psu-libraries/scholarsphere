# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkPolicy, type: :policy do
  subject { described_class }

  let(:depositor) { create(:user) }
  let(:depositor_actor) { depositor.actor }
  let(:proxy) { create(:user) }
  let(:proxy_actor) { proxy.actor }
  let(:edit_user) { build_stubbed :user }
  let(:discover_user) { build_stubbed :user }
  let(:other_user) { build_stubbed :user }
  let(:public) { User.guest }
  let(:admin) { create(:user, :admin) }
  let(:application) { create(:external_app) }

  permissions :show? do
    context 'with a public work' do
      let(:work) do
        create :work, has_draft: false,
               depositor: depositor_actor,
               proxy_depositor: proxy_actor,
               discover_users: [discover_user],
               edit_users: [edit_user]
      end

      it { is_expected.to permit(depositor, work) }
      it { is_expected.to permit(proxy, work) }
      it { is_expected.to permit(edit_user, work) }
      it { is_expected.to permit(discover_user, work) }
      it { is_expected.to permit(other_user, work) }
      it { is_expected.to permit(public, work) }
      it { is_expected.to permit(admin, work) }
      it { is_expected.to permit(application, work) }
    end

    context 'with a draft work' do
      let(:work) do
        create :work, has_draft: true,
               depositor: depositor_actor,
               proxy_depositor: proxy_actor,
               discover_users: [discover_user],
               edit_users: [edit_user]
      end

      it { is_expected.to permit(depositor, work) }
      it { is_expected.to permit(proxy, work) }
      it { is_expected.to permit(edit_user, work) }
      it { is_expected.not_to permit(discover_user, work) }
      it { is_expected.not_to permit(other_user, work) }
      it { is_expected.not_to permit(public, work) }
      it { is_expected.to permit(admin, work) }
      it { is_expected.to permit(application, work) }
    end

    context 'with a withdrawn work' do
      let(:work) do
        create :work, :withdrawn, has_draft: false,
               depositor: depositor_actor,
               proxy_depositor: proxy_actor,
               discover_users: [discover_user],
               edit_users: [edit_user]
      end

      it { is_expected.to permit(depositor, work) }
      it { is_expected.to permit(proxy, work) }
      it { is_expected.to permit(edit_user, work) }
      it { is_expected.not_to permit(discover_user, work) }
      it { is_expected.not_to permit(other_user, work) }
      it { is_expected.not_to permit(public, work) }
      it { is_expected.to permit(admin, work) }
      it { is_expected.to permit(application, work) }
    end
  end

  permissions :edit?, :update? do
    let(:work) do
      create :work,
             depositor: depositor_actor,
             proxy_depositor: proxy_actor,
             discover_users: [discover_user],
             edit_users: [edit_user]
    end

    it { is_expected.to permit(depositor, work) }
    it { is_expected.to permit(proxy, work) }
    it { is_expected.to permit(edit_user, work) }
    it { is_expected.not_to permit(discover_user, work) }
    it { is_expected.not_to permit(other_user, work) }
    it { is_expected.not_to permit(public, work) }
    it { is_expected.to permit(admin, work) }
    it { is_expected.to permit(application, work) }
  end

  permissions :create_version? do
    context 'when a draft exists' do
      let(:work) do
        create :work, has_draft: true,
                      depositor: depositor_actor,
                      proxy_depositor: proxy_actor,
                      discover_users: [discover_user],
                      edit_users: [edit_user]
      end

      it { is_expected.not_to permit(depositor, work) }
      it { is_expected.not_to permit(proxy, work) }
      it { is_expected.not_to permit(edit_user, work) }
      it { is_expected.not_to permit(discover_user, work) }
      it { is_expected.not_to permit(other_user, work) }
      it { is_expected.not_to permit(public, work) }
      it { is_expected.not_to permit(admin, work) }
      it { is_expected.not_to permit(application, work) }
    end

    context 'when no draft exists' do
      let(:work) do
        create :work, has_draft: false,
                      depositor: depositor_actor,
                      proxy_depositor: proxy_actor,
                      discover_users: [discover_user],
                      edit_users: [edit_user]
      end

      it { is_expected.to permit(depositor, work) }
      it { is_expected.to permit(proxy, work) }
      it { is_expected.to permit(edit_user, work) }
      it { is_expected.not_to permit(discover_user, work) }
      it { is_expected.not_to permit(other_user, work) }
      it { is_expected.not_to permit(public, work) }
      it { is_expected.to permit(admin, work) }
      it { is_expected.to permit(application, work) }
    end

    context 'when the work is withdrawn' do
      let(:work) do
        create :work, :withdrawn, has_draft: false,
                      depositor: depositor_actor,
                      proxy_depositor: proxy_actor,
                      discover_users: [discover_user],
                      edit_users: [edit_user]
      end

      it { is_expected.to permit(depositor, work) }
      it { is_expected.to permit(proxy, work) }
      it { is_expected.to permit(edit_user, work) }
      it { is_expected.not_to permit(discover_user, work) }
      it { is_expected.not_to permit(other_user, work) }
      it { is_expected.not_to permit(public, work) }
      it { is_expected.to permit(admin, work) }
      it { is_expected.to permit(application, work) }
    end
  end

  permissions :mint_doi? do
    context 'when a published version exists' do
      let(:work) do
        create :work, has_draft: false,
                      versions_count: 1,
                      depositor: depositor_actor,
                      proxy_depositor: proxy_actor,
                      discover_users: [discover_user],
                      edit_users: [edit_user]
      end

      it { is_expected.to permit(depositor, work) }
      it { is_expected.to permit(proxy, work) }
      it { is_expected.to permit(edit_user, work) }
      it { is_expected.not_to permit(discover_user, work) }
      it { is_expected.not_to permit(other_user, work) }
      it { is_expected.not_to permit(public, work) }
      it { is_expected.to permit(admin, work) }
      it { is_expected.to permit(application, work) }
    end

    context 'when no published version exists' do
      let(:work) do
        create :work, has_draft: true,
                      versions_count: 1,
                      depositor: depositor_actor,
                      proxy_depositor: proxy_actor,
                      discover_users: [discover_user],
                      edit_users: [edit_user]
      end

      it { is_expected.not_to permit(depositor, work) }
      it { is_expected.not_to permit(proxy, work) }
      it { is_expected.not_to permit(edit_user, work) }
      it { is_expected.not_to permit(discover_user, work) }
      it { is_expected.not_to permit(other_user, work) }
      it { is_expected.not_to permit(public, work) }
      it { is_expected.not_to permit(admin, work) }
      it { is_expected.not_to permit(application, work) }
    end
  end
end
