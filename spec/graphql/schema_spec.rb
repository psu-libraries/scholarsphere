# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Schema do
  subject(:result) { described_class.execute(query_string) }

  let(:query_string) do
    <<-QUERY
      {
        work(id: "#{resource.uuid}") {
          title
          description
          files {
            filename
            mimeType
            size
          }
        }
      }
    QUERY
  end

  context 'when querying with a work uuid' do
    let(:resource) { create(:work) }

    specify do
      expect(result.dig('data', 'work', 'title')).to eq(resource.versions[0].title)
    end
  end

  context 'when the resources has available files' do
    let(:work_version) { create(:work_version, :with_files, :published) }
    let(:file_name) { work_version.file_resources[0].file_data.dig('metadata', 'filename') }
    let(:resource) { work_version.work }

    specify do
      expect(result.dig('data', 'work', 'files')).to include(
        'filename' => file_name.to_s, 'mimeType' => 'image/png', 'size' => 63960
      )
    end
  end

  context 'when policy prevents downloading files' do
    let(:work_version) { create(:work_version, :with_files) }
    let(:resource) { work_version.work }

    specify do
      expect(result.dig('data', 'work', 'files')).to be_empty
    end
  end

  context 'when querying with a work version uuid' do
    let(:resource) { create(:work_version, :published) }

    specify do
      expect(result.dig('data', 'work', 'title')).to eq(resource.title)
    end
  end

  context 'when querying with a collection uuid' do
    let(:resource) { create(:collection) }

    specify do
      expect(result.dig('data', 'work', 'title')).to be_nil
    end
  end
end
