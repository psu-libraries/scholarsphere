# frozen_string_literal: true

require 'rails_helper'

describe DeleteCollection do
  subject(:delete_result) { described_class.call(collection.uuid) }

  let(:collection) { create(:collection, works: [work1, work2]) }

  let!(:work1) { create(:work, has_draft: false, versions_count: 1) }
  let!(:work2) { create(:work, has_draft: false, versions_count: 2) }

  context 'when the collection cannot be found' do
    it 'returns false' do
      result = described_class.call('123')

      expect(result.successful?).to be false
    end
  end

  context 'when the collection is found' do
    context 'when the collection is able to be deleted' do
      it 'deletes the collection and all of its works and their versions' do
        expect { delete_result }.to change(WorkVersion, :count).by -3

        expect { collection.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { work1.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { work2.reload }.to raise_error(ActiveRecord::RecordNotFound)

        expect(delete_result).to be_successful
      end
    end

    context 'when the database transaction fails' do
      before do
        allow(DestroyWorkVersion).to receive(:call).and_raise(StandardError)
      end

      it 'rolls back all changes' do
        expect {
          begin
            delete_result
          rescue StandardError
            # noop
          end
        }.not_to change(WorkVersion, :count)

        expect(work1.reload).to be_present
        expect(work2.reload).to be_present
        expect(collection.reload).to be_present
      end
    end
  end
end
