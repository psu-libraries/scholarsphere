# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FindResource, type: :model do
  describe '.call' do
    context 'when requesting a Work' do
      let(:work) { create(:work, has_draft: false) }

      it 'returns the Work' do
        expect(described_class.call(work.uuid)).to eq work
      end
    end

    context 'when requesting a WorkVersion' do
      let(:work_version) { create(:work_version) }

      it 'returns the WorkVersion' do
        expect(described_class.call(work_version.uuid)).to eq work_version
      end
    end

    context 'when requesting a Collection' do
      let(:collection) { create(:collection) }

      it 'returns the WorkVersion' do
        expect(described_class.call(collection.uuid)).to eq collection
      end
    end

    context 'when requesting an unknown uuid' do
      it do
        expect {
          described_class.call('unknown-uuid')
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
