# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionPolicy, type: :policy do
  subject { described_class }

  let(:depositor) { create(:user) }
  let(:depositor_actor) { depositor.actor }
  let(:edit_user) { build_stubbed(:user) }
  let(:discover_user) { build_stubbed(:user) }
  let(:other_user) { build_stubbed(:user) }
  let(:public) { User.guest }
  let(:admin) { create(:user, :admin) }
  let(:viewer) { create(:user, :viewer) }
  let(:application) { create(:external_app) }

  permissions '.scope' do
    subject(:scoped_collections) { described_class::Scope.new(depositor, Collection).resolve }

    let(:depositors_collection) { create(:collection, depositor: depositor_actor) }

    before { create(:collection) }

    it { is_expected.to contain_exactly(depositors_collection) }
  end

  permissions :show? do
    context 'with a public collection' do
      let(:collection) do
        create(:collection,
               depositor: depositor_actor)
      end

      it { is_expected.to permit(depositor, collection) }
      it { is_expected.to permit(edit_user, collection) }
      it { is_expected.to permit(discover_user, collection) }
      it { is_expected.to permit(other_user, collection) }
      it { is_expected.to permit(public, collection) }
      it { is_expected.to permit(admin, collection) }
      it { is_expected.to permit(viewer, collection) }
      it { is_expected.to permit(application, collection) }
    end

    context 'with a restricted collection' do
      let(:collection) do
        create(:collection, :with_no_access,
               depositor: depositor_actor)
      end

      it { is_expected.to permit(depositor, collection) }
      it { is_expected.not_to permit(edit_user, collection) }
      it { is_expected.not_to permit(discover_user, collection) }
      it { is_expected.not_to permit(other_user, collection) }
      it { is_expected.not_to permit(public, collection) }
      it { is_expected.to permit(admin, collection) }
      it { is_expected.not_to permit(viewer, collection) }
      it { is_expected.to permit(application, collection) }
    end

    context 'when granting discover access to a specific user' do
      let(:collection) do
        create(:collection, :with_no_access,
               depositor: depositor_actor)
      end

      before { collection.discover_users = [discover_user] }

      it { is_expected.to permit(depositor, collection) }
      it { is_expected.not_to permit(edit_user, collection) }
      it { is_expected.to permit(discover_user, collection) }
      it { is_expected.not_to permit(other_user, collection) }
      it { is_expected.not_to permit(public, collection) }
      it { is_expected.to permit(admin, collection) }
      it { is_expected.not_to permit(viewer, collection) }
      it { is_expected.to permit(application, collection) }
    end
  end

  permissions :edit?, :update?, :mint_doi? do
    let(:collection) do
      create(:collection,
             depositor: depositor_actor,
             edit_users: [edit_user])
    end

    it { is_expected.to permit(depositor, collection) }
    it { is_expected.to permit(edit_user, collection) }
    it { is_expected.not_to permit(discover_user, collection) }
    it { is_expected.not_to permit(other_user, collection) }
    it { is_expected.not_to permit(public, collection) }
    it { is_expected.to permit(admin, collection) }
    it { is_expected.not_to permit(viewer, collection) }
    it { is_expected.to permit(application, collection) }
  end

  permissions :destroy? do
    let(:collection) do
      create(:collection,
             depositor: depositor_actor,
             edit_users: [edit_user])
    end

    context 'when the collection does NOT have a doi' do
      before { collection.doi = nil }

      it { is_expected.to permit(depositor, collection) }
      it { is_expected.to permit(edit_user, collection) }
      it { is_expected.not_to permit(discover_user, collection) }
      it { is_expected.not_to permit(other_user, collection) }
      it { is_expected.not_to permit(public, collection) }
      it { is_expected.to permit(admin, collection) }
      it { is_expected.not_to permit(viewer, collection) }
      it { is_expected.to permit(application, collection) }
    end

    context 'when the collection DOES have a doi' do
      before { collection.doi = FactoryBotHelpers.valid_doi }

      it { is_expected.not_to permit(depositor, collection) }
      it { is_expected.not_to permit(edit_user, collection) }
      it { is_expected.not_to permit(discover_user, collection) }
      it { is_expected.not_to permit(other_user, collection) }
      it { is_expected.not_to permit(public, collection) }
      it { is_expected.to permit(admin, collection) }
      it { is_expected.not_to permit(viewer, collection) }
      it { is_expected.to permit(application, collection) }
    end
  end
end
