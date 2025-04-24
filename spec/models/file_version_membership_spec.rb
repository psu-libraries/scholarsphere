# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileVersionMembership do
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
    subject(:membership) { create(:file_version_membership) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_uniqueness_of(:title).scoped_to(:work_version_id) }

    it 'validates that the file extension cannot change' do
      membership.title = 'wrong.extension'
      membership.validate
      expect(membership.errors[:title]).to include(a_string_matching(/extension/))
    end
  end

  describe 'after_destroy callback' do
    let(:file_resource) { create(:file_resource) }

    context 'when the file_resource becomes orphaned' do
      it 'destroys the file_resource' do
        file_version_membership = create(:file_version_membership, file_resource: file_resource)
        expect(FileResource.exists?(file_resource.id)).to be true

        file_version_membership.destroy
        expect(FileResource.exists?(file_resource.id)).to be false
      end
    end

    context 'when the file_resource is not orphaned' do
      it 'does not destroy the file_resource' do
        file_version_membership1 = create(:file_version_membership, file_resource: file_resource)
        create(:file_version_membership, file_resource: file_resource)
        expect(FileResource.exists?(file_resource.id)).to be true

        file_version_membership1.destroy
        expect(FileResource.exists?(file_resource.id)).to be true
      end
    end
  end

  describe 'delegate methods' do
    subject(:membership) { build(:file_version_membership) }

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

  describe 'PaperTrail::Versions', :versioning do
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
      subject(:membership) { build(:file_version_membership) }

      it "initializes #title to the file's filename before validation" do
        expect { membership.validate }
          .to change(membership, :title)
          .from(nil)
          .to(membership.file_resource.file.original_filename)
      end
    end

    context 'when title is provided' do
      subject(:membership) { build(:file_version_membership, title: 'provided_a_filename.png') }

      it "initializes #title to the file's filename before validation" do
        expect { membership.validate }
          .not_to change(membership, :title)
          .from('provided_a_filename.png')
      end
    end
  end

  describe '#accessibility_result' do
    let(:file_version_membership) { create(:file_version_membership) }
    let(:accessibility_check_result) do
      create(:accessibility_check_result, file_resource_id: file_version_membership.file_resource.id)
    end

    before { accessibility_check_result.save! }

    it 'returns the file resource accessibility result' do
      expect(file_version_membership.accessibility_result).to eq accessibility_check_result
    end
  end

  describe '#accessibility_score' do
    let(:file_version_membership) { create(:file_version_membership) }
    let(:accessibility_check_result) do
      create(:accessibility_check_result, file_resource_id: file_version_membership.file_resource.id, detailed_report: detailed_report)
    end
    let(:detailed_report) {
      { 'Detailed Report' => {
        'Forms' =>
        [{ 'Rule' => 'Tagged form fields', 'Status' => 'Passed', 'Description' => 'All form fields are tagged' }],
        'Tables' =>
      [{ 'Rule' => 'Rows', 'Status' => 'Passed', 'Description' => 'TR must be a child of Table, THead, TBody, or TFoot' }],
        'Document' =>
      [{ 'Rule' => 'Accessibility permission flag', 'Status' => 'Failed', 'Description' => 'Accessibility permission flag must be set' },
       { 'Rule' => 'Image-only PDF', 'Status' => 'Needs manual check', 'Description' => 'Document is not image-only PDF' }]
      } } }

    before { accessibility_check_result.save! }

    it 'returns the file resource accessibility score' do
      expect(file_version_membership.accessibility_score).to eq '2 out of 4 passed'
    end
  end

  describe '#accessibility_error_present?' do
    let(:file_version_membership) { create(:file_version_membership) }

    context 'when there is a check result' do
      context 'when the result has a detailed report' do
        let(:accessibility_check_result) do
          create(:accessibility_check_result, file_resource_id: file_version_membership.file_resource.id)
        end

        before { accessibility_check_result.save! }

        it 'returns false' do
          expect(file_version_membership.accessibility_error_present?).to eq false
        end
      end

      context 'when the result has an error' do
        let(:accessibility_check_result) do
          create(:accessibility_check_result, file_resource_id: file_version_membership.file_resource.id, detailed_report: detailed_report)
        end
        let(:detailed_report) {
{ 'error' => 'Authentication failed: 400 - {"error":{"code":"invalid_client","message":"invalid client_id parameter"}}' } }

        before { accessibility_check_result.save! }

        it 'returns true' do
          expect(file_version_membership.accessibility_error_present?).to eq true
        end
      end
    end

    context 'when there is not a check result' do
      it 'returns false' do
        expect(file_version_membership.accessibility_error_present?).to eq false
      end
    end
  end

  describe '#accessibility_score_present?' do
    let(:file_version_membership) { create(:file_version_membership) }

    context 'when there is a check result' do
      context 'when the result has a detailed report' do
        let(:accessibility_check_result) do
          create(:accessibility_check_result, file_resource_id: file_version_membership.file_resource.id)
        end

        before { accessibility_check_result.save! }

        it 'returns true' do
          expect(file_version_membership.accessibility_score_present?).to eq true
        end
      end

      context 'when the result has an error' do
        let(:accessibility_check_result) do
          create(:accessibility_check_result, file_resource_id: file_version_membership.file_resource.id, detailed_report: detailed_report)
        end
        let(:detailed_report) {
{ 'error' => 'Authentication failed: 400 - {"error":{"code":"invalid_client","message":"invalid client_id parameter"}}' } }

        before { accessibility_check_result.save! }

        it 'returns false' do
          expect(file_version_membership.accessibility_score_present?).to eq false
        end
      end
    end

    context 'when there is not a check result' do
      it 'returns false' do
        expect(file_version_membership.accessibility_score_present?).to eq false
      end
    end
  end

  describe '#accessibility_score_pending?' do
    let(:file_version_membership) { create(:file_version_membership, file_resource: file) }
    let(:file) { create(:file_resource) }

    context 'when there is not a check result' do
      context 'when the file is a pdf' do
        let(:file) { create(:file_resource, :pdf) }

        it 'returns true' do
          expect(file_version_membership.accessibility_score_pending?).to eq true
        end
      end

      context 'when the file is not a pdf' do
        it 'returns false' do
          expect(file_version_membership.accessibility_score_pending?).to eq false
        end
      end
    end

    context 'when there is a check result' do
      let(:accessibility_check_result) do
        create(:accessibility_check_result, file_resource_id: file_version_membership.file_resource.id)
      end

      before { accessibility_check_result.save! }

      it 'returns false' do
        expect(file_version_membership.accessibility_score_pending?).to eq false
      end
    end
  end

  describe '#accessibility_failures?' do
    let(:file_version_membership) { create(:file_version_membership) }

    context 'when there is a check result' do
      context 'when the result has failures' do
        let(:accessibility_check_result) do
          create(:accessibility_check_result, file_resource_id: file_version_membership.file_resource.id, detailed_report: detailed_report)
        end
        let(:detailed_report) {
          { 'Detailed Report' => {
            'Forms' =>
            [{ 'Rule' => 'Tagged form fields', 'Status' => 'Passed', 'Description' => 'All form fields are tagged' }],
            'Tables' =>
          [{ 'Rule' => 'Rows', 'Status' => 'Passed', 'Description' => 'TR must be a child of Table, THead, TBody, or TFoot' }],
            'Document' =>
          [{ 'Rule' => 'Accessibility permission flag', 'Status' => 'Failed', 'Description' => 'Accessibility permission flag must be set' },
           { 'Rule' => 'Image-only PDF', 'Status' => 'Passed', 'Description' => 'Document is not image-only PDF' }]
          } }}

        before { accessibility_check_result.save! }

        it 'returns true' do
          expect(file_version_membership.accessibility_failures?).to eq true
        end
      end

      context 'when the result has a rule that needs manual check' do
        let(:accessibility_check_result) do
          create(:accessibility_check_result, file_resource_id: file_version_membership.file_resource.id, detailed_report: detailed_report)
        end
        let(:detailed_report) {
          { 'Detailed Report' => {
            'Forms' =>
            [{ 'Rule' => 'Tagged form fields', 'Status' => 'Passed', 'Description' => 'All form fields are tagged' }],
            'Tables' =>
          [{ 'Rule' => 'Rows', 'Status' => 'Passed', 'Description' => 'TR must be a child of Table, THead, TBody, or TFoot' }],
            'Document' =>
          [{ 'Rule' => 'Accessibility permission flag', 'Status' => 'Needs manual check', 'Description' => 'Accessibility permission flag must be set' },
           { 'Rule' => 'Image-only PDF', 'Status' => 'Passed', 'Description' => 'Document is not image-only PDF' }]
          } }}

        before { accessibility_check_result.save! }

        it 'returns true' do
          expect(file_version_membership.accessibility_failures?).to eq true
        end
      end

      context 'when all rules pass' do
        let(:accessibility_check_result) do
          create(:accessibility_check_result, file_resource_id: file_version_membership.file_resource.id, detailed_report: detailed_report)
        end
        let(:detailed_report) {
          { 'Detailed Report' => {
            'Forms' =>
            [{ 'Rule' => 'Tagged form fields', 'Status' => 'Passed', 'Description' => 'All form fields are tagged' }],
            'Tables' =>
          [{ 'Rule' => 'Rows', 'Status' => 'Passed', 'Description' => 'TR must be a child of Table, THead, TBody, or TFoot' }],
            'Document' =>
          [{ 'Rule' => 'Accessibility permission flag', 'Status' => 'Passed', 'Description' => 'Accessibility permission flag must be set' },
           { 'Rule' => 'Image-only PDF', 'Status' => 'Passed', 'Description' => 'Document is not image-only PDF' }]
          } }}

        before { accessibility_check_result.save! }

        it 'returns false' do
          expect(file_version_membership.accessibility_failures?).to eq false
        end
      end
    end

    context 'when there is not a check result' do
      it 'returns true' do
        expect(file_version_membership.accessibility_failures?).to eq true
      end
    end
  end

  describe '#accessibility_report_download_url' do
    let(:file_version_membership) { create(:file_version_membership) }

    context 'when there is a detailed report present' do
      let(:accessibility_check_result) do
        create(:accessibility_check_result, file_resource_id: file_version_membership.file_resource.id)
      end
      let(:expected_url) { "/accessibility_check_results/#{accessibility_check_result.id}" }

      before { accessibility_check_result.save! }

      it 'returns the url to view the accessibility report' do
        expect(file_version_membership.accessibility_report_download_url).to eq expected_url
      end
    end

    context 'when there is an error present' do
      let(:accessibility_check_result) do
        create(:accessibility_check_result, file_resource_id: file_version_membership.file_resource.id, detailed_report: detailed_report)
      end
      let(:detailed_report) {
{ 'error' => 'Authentication failed: 400 - {"error":{"code":"invalid_client","message":"invalid client_id parameter"}}' } }

      before { accessibility_check_result.save! }

      it 'returns nil' do
        expect(file_version_membership.accessibility_report_download_url).to be_nil
      end
    end
  end
end
