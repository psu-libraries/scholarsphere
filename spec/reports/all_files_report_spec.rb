# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AllFilesReport do
  subject(:report) { described_class.new }

  it_behaves_like 'a report' do
    subject { report }
  end

  describe '#headers' do
    specify { expect(report.headers).to eq %w[id version_id filename mime_type size md5 sha256 downloads] }
  end

  describe '#name' do
    specify { expect(report.name).to eq 'all_files' }
  end

  describe '#rows' do
    let!(:file1) { create :file_resource }
    let!(:file2) { create :file_resource }

    let!(:work_published) { create :work, has_draft: false, versions_count: 2 }

    let(:version1) { work_published.versions[0] }
    let(:version2) { work_published.versions[1] }

    before do
      # Set all versions of the published work to point to the same files,
      # which more accurately reflects production data
      work_published.versions.each do |work_version|
        work_version.file_resources = [file1, file2]
        work_version.save!
      end

      # Create view (download) statistics for file(s)
      create :view_statistic, resource: file1, count: 1
      create :view_statistic, resource: file1, count: 3

      # Create checksums for one of the files
      # TODO: checksums are not currently implemented, but will be soon. This may need to be updated
      file1.file_attacher.tap do |attacher|
        attacher.file.add_metadata('md5' => 'md5offile1', 'sha256' => 'sha256offile1')
        attacher.write
      end
      file1.save!

      # Change the filename of file2-version2's membership
      version2
        .file_version_memberships
        .find_by(file_resource_id: file2)
        .update!(title: 'a-new-filename.png')

      # Delete all other files (which were created as a side effect of factorybot)
      FileResource
        .where.not(id: [file1, file2])
        .destroy_all
    end

    it 'yields each row to the given block' do
      # Sanity Check
      expect(FileResource.count).to eq 2

      yielded_rows = []
      report.rows do |row|
        yielded_rows << row
      end

      # Test that there is one row for each FileResource x WorkVersion combo
      # This test is a litte complicated because order is not guaranteed when using `find_each`
      expect(yielded_rows.map { |row| [row[0], row[1]] }).to contain_exactly(
        [file1.uuid, version1.uuid],
        [file1.uuid, version2.uuid],
        [file2.uuid, version1.uuid],
        [file2.uuid, version2.uuid]
      )

      # Grab a known row
      file1_version1_row = yielded_rows
        .find { |file_uuid, version_uuid, *_rest| file_uuid == file1.uuid && version_uuid == version1.uuid }
      expect(file1_version1_row[2]).to eq version1.file_version_memberships.find_by(file_resource_id: file1).title
      expect(file1_version1_row[3]).to eq file1.file.metadata['mime_type']
      expect(file1_version1_row[4]).to eq file1.file.metadata['size']
      expect(file1_version1_row[5]).to eq 'md5offile1'
      expect(file1_version1_row[6]).to eq 'sha256offile1'
      expect(file1_version1_row[7]).to eq 4

      # Spot check another row
      file2_version2_row = yielded_rows
        .find { |file_uuid, version_uuid, *_rest| file_uuid == file2.uuid && version_uuid == version2.uuid }
      expect(file2_version2_row[2]).to eq 'a-new-filename.png'
      expect(file2_version2_row[5]).to be_blank # No md5
      expect(file2_version2_row[6]).to be_blank # No sha
      expect(file2_version2_row[7]).to eq 0 # No downloads
    end
  end
end
