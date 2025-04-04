# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionDecorator do
  subject(:decorator) { described_class.new(collection) }

  it 'extends ResourceDecorator' do
    expect(described_class).to be < ResourceDecorator
  end

  describe '#decorated_work_versions' do
    let(:work_1) { create(:work, versions_count: 2, has_draft: true) }
    let(:work_1_published_version) { work_1.latest_published_version }

    let(:work_2) { create(:work, versions_count: 1, has_draft: false) }
    let(:work_2_published_version) { work_2.latest_published_version }

    # Note, this work has no published version, only a draft
    let(:work_3) { create(:work, versions_count: 1, has_draft: true) }

    let(:collection) { create(:collection, works: [work_1, work_2, work_3]) }

    it 'returns an array of the latest published versions of all works in the collection, decorated' do
      work_versions = decorator.decorated_work_versions

      expect(work_versions.map(&:id)).to contain_exactly(
        work_1_published_version.uuid,
        work_2_published_version.uuid
      )
    end
  end
end
