# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileVersionMembership, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:work_version_id) }
    it { is_expected.to have_db_column(:file_resource_id) }
    it { is_expected.to have_db_column(:title) }

    it { is_expected.to have_db_index(:work_version_id) }
    it { is_expected.to have_db_index(:file_resource_id) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:file_version_membership) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:work_version) }
    it { is_expected.to belong_to(:file_resource) }
  end

  describe 'validations' do
    subject(:membership) { create :file_version_membership }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_uniqueness_of(:title).scoped_to(:work_version_id) }

    it 'validates that the file extension cannot change' do
      membership.title = 'wrong.extension'
      membership.validate
      expect(membership.errors[:title]).to include(a_string_matching(/extension/))
    end
  end

  describe 'delegate methods' do
    subject(:membership) { build :file_version_membership }

    let(:mock_uploader) { instance_spy('FileUploader::UploadedFile') }

    before { allow(membership.file_resource).to receive(:file).and_return(mock_uploader) }

    it "delegates #size to the FileResource's uploader" do
      membership.size
      expect(mock_uploader).to have_received(:size)
    end

    it "delegates #original_filename to the FileResource's uploader" do
      membership.original_filename
      expect(mock_uploader).to have_received(:original_filename)
    end

    it "delegates #mime_type to the FileResource's uploader" do
      membership.mime_type
      expect(mock_uploader).to have_received(:mime_type)
    end

    it "delegates #virus to the FileResource's uploader" do
      membership.virus
      expect(mock_uploader).to have_received(:virus)
    end

    it "delegates #sha256 to the FileResource's uploader" do
      membership.sha256
      expect(mock_uploader).to have_received(:sha256)
    end

    it "delegates #md5 to the FileResource's uploader" do
      membership.md5
      expect(mock_uploader).to have_received(:md5)
    end
  end

  describe 'PaperTrail::Versions', versioning: true do
    it { is_expected.to respond_to(:changed_by_system).and respond_to(:changed_by_system=) }
    it { is_expected.to be_versioned }

    context 'when the record is marked as changed by the system' do
      let(:file_version_membership) { create(:file_version_membership, changed_by_system: true) }

      it "writes a version with the flag saved in PaperTrail's metadata" do
        expect(file_version_membership.reload.versions.length).to eq 1

        paper_trail_version = file_version_membership.versions.first

        expect(paper_trail_version.changed_by_system).to eq(true)
      end
    end

    context 'when the record is NOT marked as changed by the system' do
      let(:file_version_membership) { create(:file_version_membership, changed_by_system: false) }

      it "writes a version and stores the record's type and id into the version metadata" do
        paper_trail_version = file_version_membership.versions.first

        expect(paper_trail_version.resource_id).to eq(file_version_membership.work_version_id)
        expect(paper_trail_version.resource_type).to eq('WorkVersion')
        expect(paper_trail_version.changed_by_system).to eq(false)
      end
    end
  end

  describe 'initializing #title' do
    # NOTE the :file_resource factory is created with a file named 'image.png'

    context 'when no title is provided' do
      subject(:membership) { build :file_version_membership }

      it "initializes #title to the file's filename before validation" do
        expect { membership.validate }
          .to change(membership, :title)
          .from(nil)
          .to(membership.file_resource.file.original_filename)
      end
    end

    context 'when title is provided' do
      subject(:membership) { build :file_version_membership, title: 'provided_a_filename.png' }

      it "initializes #title to the file's filename before validation" do
        expect { membership.validate }
          .not_to change(membership, :title)
          .from('provided_a_filename.png')
      end
    end
  end
end
