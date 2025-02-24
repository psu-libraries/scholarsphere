# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionWorkMembership do
  describe 'table' do
    it { is_expected.to have_db_column(:collection_id) }
    it { is_expected.to have_db_column(:work_id) }
    it { is_expected.to have_db_column(:position).of_type(:integer) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }

    it { is_expected.to have_db_index(:collection_id) }
    it { is_expected.to have_db_index(:work_id) }
  end

  describe 'factory' do
    it { is_expected.to have_valid_factory(:collection_work_membership) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:collection) }
    it { is_expected.to belong_to(:work) }
  end

  describe 'validations' do
    let(:work) { create(:work) }
    let(:collection) { create(:collection) }

    it 'validates that a collection cannot contain the same work twice' do
      create(:collection_work_membership, collection: collection, work: work)

      second_one = build(:collection_work_membership, collection: collection, work: work)
      expect(second_one).not_to be_valid
    end
  end

  describe 'after_create' do
    context 'when the associated collection has just been created (does not have any collection_work_memberships)' do
      let(:collection) { create(:collection) }
      let(:work) { create(:work) }

      context 'when the associated work has an auto_generated_thumbnail_url' do
        it "updates the associated collection's thumbnail_selection to '#{ThumbnailSelections::AUTO_GENERATED}'}" do
          allow_any_instance_of(Work).to receive(:auto_generated_thumbnail_url).and_return 'url.com/path/file'
          expect(collection.thumbnail_selection).to eq ThumbnailSelections::DEFAULT_ICON
          collection.attributes = {
            'collection_work_memberships_attributes' => {
              '0' => { 'work_id' => work.id.to_s,
                       '_destroy' => 'false',
                       'position' => '1' }
            }
          }
          collection.save
          expect(collection.reload.thumbnail_selection).to eq ThumbnailSelections::AUTO_GENERATED
        end
      end

      context 'when the associated work does not have an auto_generated_thumbnail_url' do
        it "the associated collection's thumbnail_selection remains as '#{ThumbnailSelections::DEFAULT_ICON}" do
          expect(collection.thumbnail_selection).to eq ThumbnailSelections::DEFAULT_ICON
          collection.attributes = {
            'collection_work_memberships_attributes' => {
              '0' => { 'work_id' => work.id.to_s,
                       '_destroy' => 'false',
                       'position' => '1' }
            }
          }
          collection.save
          expect(collection.reload.thumbnail_selection).to eq ThumbnailSelections::DEFAULT_ICON
        end
      end
    end

    context 'when the associated collection already has associated works' do
      let(:collection) { create(:collection) }
      let(:work) { create(:work) }

      before do
        collection.works << (create(:work))
        collection.save
      end

      it "the associated collection's thumbnail_selection remains as '#{ThumbnailSelections::DEFAULT_ICON}" do
        allow_any_instance_of(Work).to receive(:auto_generated_thumbnail_url).and_return 'url.com/path/file'
        expect(collection.thumbnail_selection).to eq ThumbnailSelections::DEFAULT_ICON
        collection.attributes = {
          'collection_work_memberships_attributes' => {
            '0' => { 'work_id' => work.id.to_s,
                     '_destroy' => 'false',
                     'position' => '1' }
          }
        }
        collection.save
        expect(collection.reload.thumbnail_selection).to eq ThumbnailSelections::DEFAULT_ICON
      end
    end
  end
end
