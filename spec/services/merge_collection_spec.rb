# frozen_string_literal: true

require 'rails_helper'

describe MergeCollection do
  subject(:merge_result) { described_class.call(collection.uuid) }

  let(:collection) { create(:collection, works: [work1, work2]) }
  let(:user) { create(:user) }
  let(:actor) { user.actor }

  let(:work1) { create(:work, has_draft: false, depositor: actor) }
  let(:work2) { create(:work, has_draft: false, depositor: actor) }
  let(:common_metadata) { attributes_for(:work_version, :published, :with_complete_metadata) }

  # Update both works to have identical metadata on their versions, so we can induce various error states easily
  before do
    work1.versions.first.update(common_metadata)
    work2.versions.first.update(common_metadata)

    work2.versions.first.creators = work1.versions.first.creators.map(&:dup)
    work2.save!
  end

  context 'when the works in the collection are inelegible to be merged' do
    context 'when a work has too many versions' do
      let(:work1) { create(:work, versions_count: 1, has_draft: false) }
      let(:work2) { create(:work, versions_count: 2, has_draft: false) }

      it 'returns an error message' do
        error_msg = "Work-#{work2.id} has 2 work versions, but must only have 1"
        expect(merge_result.errors).to include(a_string_matching(error_msg))
      end
    end

    context 'when a work has too many files' do
      let (:work1) { create(:work, versions: [v1], depositor: actor) }
      let (:work2) { create(:work, has_draft: false, depositor: actor) }
      let (:v1) { create(:work_version, :with_files, :published, file_count: 2) }

      it 'returns an error message' do
        expect(merge_result.errors).to include("Work-#{work1.id} has 2 files, but must only have 1")
      end
    end

    context 'when the works in the collection have mismatched work-level metadata' do
      let(:work1) { create(:work, has_draft: false) }
      let(:work2) { create(:work, has_draft: false) }

      it 'returns an error message' do
        error_msg = /Work-#{work1.id} has different work metadata than Work-#{work2.id}/i
        expect(merge_result.errors).to include(a_string_matching(error_msg))
      end
    end

    context 'when the resulting work has an ActiveRecord validation error' do
      before do
        collection # create collection in db

        # Force work1 to be invalid
        work1.work_type = nil
        work1.save(validate: false)
        work2.work_type = nil
        work2.save(validate: false)
      end

      it 'adds any ActiveRecord validation errors on the new work to the errors array' do
        expect(merge_result.errors).to include(a_string_matching(/work type can't be blank/i))
      end
    end

    context 'when the works in the collection have mismatched version-level metadata' do
      before do
        work1.versions.first.update(description: 'new description')
      end

      it 'returns an error message' do
        error_msg = /Work-#{work1.id} has different WorkVersion metadata than Work-#{work2.id}/i
        expect(merge_result.errors).to include(a_string_matching(error_msg))
        expect(merge_result.errors).to include(a_string_matching(/new description/i))
      end
    end

    context 'when a work in the collection is not published' do
      before do
        work1.versions.first.update(aasm_state: 'draft')
      end

      it 'returns an error message' do
        expect(merge_result.errors).to include("Work-#{work1.id} is not published")
      end
    end

    context 'when the works in the collection have mismatched access controls' do
      let(:edit_user) { create(:user) }
      let(:work1) { create(:work, has_draft: false, depositor: actor, edit_users: [edit_user]) }
      let(:work2) { create(:work, has_draft: false, depositor: actor) }

      it 'returns an error message' do
        error_msg = /Work-#{work1.id} has different discover users than Work-#{work2.id}/i
        expect(merge_result.errors).to include(a_string_matching(error_msg))
      end
    end

    context 'when the works in the collection have mismatched creators' do
      before do
        work2.versions.first.creators = build_list(:authorship, 1)
        work2.save!
      end

      it 'returns an error message' do
        error_msg = /Work-#{work1.id} has different creators than Work-#{work2.id}/i
        expect(merge_result.errors).to include(a_string_matching(error_msg))
      end
    end
  end

  context 'when the database transaction fails' do
    before do
      allow(DestroyWorkVersion).to receive(:call).and_raise(StandardError)
    end

    it 'rolls back all changes' do
      expect {
        begin
          merge_result
        rescue StandardError
          # noop
        end
      }.not_to change(Work, :count)

      expect(collection.reload).to be_present
    end
  end

  context 'when the works in the collection are eligible to be merged' do
    before do
      create(:view_statistic, resource: collection, date: Date.parse('2022-02-06'), count: 1)
      create(:view_statistic, resource: collection, date: Date.parse('2022-02-07'), count: 1)
      create(:view_statistic, resource: work1.versions.first, date: Date.parse('2022-02-07'), count: 1)
    end

    it 'merges the works into a single work' do
      expect(merge_result).to be_successful

      new_work = Work.last
      expect(new_work.versions.length).to eq 1

      version = new_work.versions.first

      # spot check attributes
      expect(version).to be_published
      expect(version.title).to eq collection.title
      expect(version.rights).to eq common_metadata[:rights]
      expect(version.description).to eq common_metadata[:description]
      expect(version.published_date).to eq common_metadata[:published_date]

      # check files
      original_files = [
        work1.versions.first.file_resources,
        work2.versions.first.file_resources
      ].flatten
      expect(version.file_resources).to match_array(original_files)

      # check creators
      expect(version.creators.map(&:display_name)).to match_array(work1.versions.first.creators.map(&:display_name))

      # check view stats
      expect(
        version.view_statistics.map { |vs| [vs.date, vs.count] }
      ).to match_array([
                         [Date.parse('2022-02-06'), 1],
                         [Date.parse('2022-02-07'), 2]
                       ])
    end

    context 'when the delete_collection param is true' do
      it 'deletes the original collection and its works' do
        merge_result
        expect { collection.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { work1.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { work2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the delete_collection param is false' do
      it 'does not delete the original collection or its works' do
        described_class.call(collection.uuid, delete_collection: false)
        expect(collection.reload).to be_present
        expect(work1.reload).to be_present
        expect(work2.reload).to be_present
      end
    end
  end
end
