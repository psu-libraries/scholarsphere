# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Actor, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:given_name).of_type(:string) }
    it { is_expected.to have_db_column(:surname).of_type(:string) }
    it { is_expected.to have_db_column(:email).of_type(:string) }
    it { is_expected.to have_db_column(:psu_id).of_type(:string) }
    it { is_expected.to have_db_column(:orcid).of_type(:string) }
    it { is_expected.to have_db_column(:default_alias).of_type(:string) }

    it { is_expected.to have_db_index(:psu_id) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:actor) }
  end

  describe 'associations' do
    it { is_expected.to have_one(:user) }
    it { is_expected.to have_many(:work_version_creations) }
    it { is_expected.to have_many(:work_versions).through(:work_version_creations) }
    it { is_expected.to have_many(:deposited_works).class_name('Work').inverse_of(:depositor) }
    it { is_expected.to have_many(:proxy_deposited_works).class_name('Work').inverse_of(:proxy_depositor) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:surname) }
  end

  describe '#default_alias' do
    let(:actor) { build :actor, given_name: 'Pat', surname: 'Researcher' }

    context 'when nil' do
      before { actor.default_alias = nil }

      it 'defaults to concatenated given and surname' do
        expect(actor.default_alias).to eq 'Pat Researcher'
      end
    end

    context 'when set' do
      before { actor.default_alias = 'Dr. Pat Q. Researcher PhD MD MLIS' }

      it 'returns the saved value' do
        expect(actor.default_alias).to eq 'Dr. Pat Q. Researcher PhD MD MLIS'
      end
    end
  end
end
