# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LegacyIdentifier do
  describe 'table' do
    it { is_expected.to have_db_column(:version).of_type(:integer) }
    it { is_expected.to have_db_column(:old_id).of_type(:string) }
    it { is_expected.to have_db_column(:resource_type).of_type(:string) }
    it { is_expected.to have_db_column(:resource_id).of_type(:integer) }

    it { is_expected.to have_db_index([:resource_type, :resource_id]) }
    it { is_expected.to have_db_index([:version, :old_id]) }
  end

  describe 'factory' do
    it { is_expected.to have_valid_factory(:legacy_identifier) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:resource) }
  end

  describe '.find_uuid' do
    let(:work_version) { create(:work_version) }

    context 'when the ID can be found' do
      before do
        create(:legacy_identifier,
               version: 1,
               old_id: 'old-123',
               resource: work_version)
      end

      it 'returns the UUID of the associated resource' do
        expect(described_class.find_uuid(version: 1, old_id: 'old-123'))
          .to eq work_version.uuid
      end
    end

    context 'when the ID cannot be found' do
      it do
        expect {
          described_class.find_uuid(version: 1, old_id: 'does not exist')
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
