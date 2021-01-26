# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Authorship, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:resource_id) }
    it { is_expected.to have_db_column(:resource_type) }
    it { is_expected.to have_db_column(:actor_id) }
    it { is_expected.to have_db_column(:display_name).of_type(:string) }
    it { is_expected.to have_db_column(:given_name).of_type(:string) }
    it { is_expected.to have_db_column(:surname).of_type(:string) }
    it { is_expected.to have_db_column(:email).of_type(:string) }
    it { is_expected.to have_db_column(:position).of_type(:integer) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }
  end

  describe 'factory' do
    it { is_expected.to have_valid_factory(:authorship) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:resource) }
    it { is_expected.to belong_to(:actor).optional }
  end

  describe 'default values' do
    context 'without a linked actor' do
      subject { described_class.new }

      its(:given_name) { is_expected.to be_nil }
      its(:surname) { is_expected.to be_nil }
      its(:email) { is_expected.to be_nil }
    end

    context 'with a linked actor' do
      subject { described_class.new(actor: actor) }

      let(:actor) { build(:actor) }

      its(:given_name) { is_expected.to eq(actor.given_name) }
      its(:surname) { is_expected.to eq(actor.surname) }
      its(:email) { is_expected.to eq(actor.email) }
    end

    context 'with existing values' do
      subject { described_class.new(given_name: 'x', surname: 'y', email: 'z', actor: actor) }

      let(:actor) { build(:actor) }

      its(:given_name) { is_expected.to eq('x') }
      its(:surname) { is_expected.to eq('y') }
      its(:email) { is_expected.to eq('z') }
    end
  end

  describe '#instance_token' do
    context 'without a token' do
      subject(:authorship) { create(:authorship) }

      its(:instance_token) { is_expected.not_to be_nil }
    end

    context 'when providing a token' do
      subject(:authorship) { create(:authorship, instance_token: token) }

      let(:token) { SecureRandom.uuid }

      its(:instance_token) { is_expected.to eq(token) }
    end
  end

  describe '#alias' do
    subject(:authorship) { build(:authorship) }

    its(:alias) { is_expected.to eq(authorship.display_name) }
  end

  describe '#alias=' do
    subject(:authorship) { build(:authorship) }

    before { authorship.alias = 'New Alias' }

    its(:alias) { is_expected.to eq('New Alias') }
  end

  describe 'singlevalued fields' do
    it_behaves_like 'a singlevalued field', :surname
    it_behaves_like 'a singlevalued field', :given_name
    it_behaves_like 'a singlevalued field', :email
  end

  describe 'PaperTrail::Versions', versioning: true do
    it { is_expected.to respond_to(:changed_by_system).and respond_to(:changed_by_system=) }
    it { is_expected.to be_versioned }

    context 'when the record is marked as changed by the system' do
      let(:authorship) { create(:authorship, changed_by_system: true) }

      it 'does not write a papertrail version' do
        expect(authorship.reload.versions).to be_empty
      end
    end

    context 'when the record is NOT marked as changed by the system' do
      let(:authorship) { create(:authorship, changed_by_system: false) }

      it "writes a version and stores the record's type and id into the version metadata" do
        paper_trail_version = authorship.versions.first

        expect(paper_trail_version.resource_id).to eq(authorship.resource_id)
        expect(paper_trail_version.resource_type).to eq(authorship.resource_type)
      end
    end
  end
end
