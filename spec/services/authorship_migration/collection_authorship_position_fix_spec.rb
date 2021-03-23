# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorshipMigration::CollectionAuthorshipPositionFix, versioning: true do
  let(:collection) { create :collection, :with_creators, creator_count: 3 }

  context "when a collection's authorships are already correct" do
    it 'does not change the positions' do
      expect(collection.creators[0].position).to eq 0
      expect(collection.creators[1].position).to eq 1
      expect(collection.creators[2].position).to eq 2

      return_val = nil
      expect {
        return_val = described_class.call
      }.not_to change(PaperTrail::Version, :count)

      expect(return_val).to eq true

      collection.reload
      expect(collection.creators[0].position).to eq 0
      expect(collection.creators[1].position).to eq 1
      expect(collection.creators[2].position).to eq 2
    end
  end

  context "when a collection's authorships are all missing a position" do
    before do
      collection.creators.find_each do |authorship|
        authorship.update_column(:position, nil)
      end
      collection.reload
    end

    it 'updates the positions' do
      expect(collection.creators[0].position).to eq nil
      expect(collection.creators[1].position).to eq nil
      expect(collection.creators[2].position).to eq nil

      return_val = nil
      expect {
        return_val = described_class.call
      }.not_to(change {
        PaperTrail::Version.where(changed_by_system: false).count
      })

      expect(return_val).to eq true

      collection.reload
      expect(collection.creators[0].position).to eq 10
      expect(collection.creators[1].position).to eq 20
      expect(collection.creators[2].position).to eq 30
    end
  end

  context 'when something is very wrong' do
    before do
      collection.creators[0].update_column(:position, nil)
      collection.reload
    end

    it 'reports the error' do
      expect(collection.creators.map(&:position)).to match_array([nil, 1, 2])

      return_val = nil
      expect {
        return_val = described_class.call
      }.not_to(change {
        PaperTrail::Version.where(changed_by_system: false).count
      })

      expect(return_val).to eq false

      collection.reload
      expect(collection.creators.map(&:position)).to match_array([nil, 1, 2])

      expect { described_class.call }.to output(/Collection##{collection.id}, can't be corrected/i).to_stdout
    end
  end
end
