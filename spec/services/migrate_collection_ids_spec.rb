# frozen_string_literal: true

require 'rails_helper'

describe MigrateCollectionIds do
  subject(:migrate_result) { described_class.call(collection.uuid, target_work.uuid) }

  let(:collection) { create(:collection, :with_a_doi, works: [work1, work2]) }

  let!(:work1) { create(:work, has_draft: false, versions_count: 1) }
  let!(:work2) { create(:work, has_draft: false, versions_count: 2) }
  let!(:target_work) { create(:work, has_draft: false, versions_count: 1) }

  let!(:legacy_id) { create(:legacy_identifier,
                            old_id: 'tb09j581r',
                            resource: collection,
                            version: 3) }

  context 'when the collection cannot be found' do
    it 'returns false' do
      result = described_class.call('123', work1.uuid)

      expect(result.successful?).to be false
    end
  end

  context 'when the work cannot be found' do
    it 'returns false' do
      result = described_class.call(collection.uuid, '123')

      expect(result.successful?).to be false
    end
  end

  context 'when the collection and work are found' do
    before do
      create(:view_statistic, resource: collection, date: Date.parse('2022-02-06'), count: 1)
      create(:view_statistic, resource: collection, date: Date.parse('2022-02-07'), count: 1)
      create(:view_statistic, resource: work1.versions.first, date: Date.parse('2022-02-07'), count: 1)
    end

    context 'when the ids are eligible to be merged' do
      before { migrate_result }

      it 'returns a successful result' do
        expect(migrate_result).to be_successful
      end

      it 'deletes the original collection + works + legacy identifiers' do
        expect { collection.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { work1.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { work2.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { legacy_id.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'copies IDs from the collection to the work' do
        target_work.reload

        expect(target_work.uuid).to eq collection.uuid
        expect(target_work.doi).not_to be_nil
        expect(target_work.doi).to eq collection.doi

        expect(target_work.legacy_identifiers.count).to eq 1

        legacy_id = target_work.legacy_identifiers.first

        expect(legacy_id.old_id).to eq 'tb09j581r'
        expect(legacy_id.resource_type).to eq 'Work'
        expect(legacy_id.resource_id).to eq target_work.id
        expect(legacy_id.version).to eq 3

        expect(
          target_work.latest_version.view_statistics.map { |vs| [vs.date, vs.count] }
        ).to contain_exactly([Date.parse('2022-02-06'), 1], [Date.parse('2022-02-07'), 2])
      end
    end

    context 'when the database transaction fails' do
      before do
        allow(IndexingService).to receive(:delete_document).and_raise(StandardError)
      end

      it 'rolls back all changes' do
        expect {
          begin
            migrate_result
          rescue StandardError
            # noop
          end
        }.not_to(change { { work_versions: WorkVersion.count, view_statistics: ViewStatistic.count } })

        expect(work1.reload).to be_present
        expect(work2.reload).to be_present
        expect(collection.reload).to be_present
      end
    end
  end
end
