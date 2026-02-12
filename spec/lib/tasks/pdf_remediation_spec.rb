# frozen_string_literal: true

require 'rails_helper'

describe 'pdf_remediation', type: :task do
  describe ':flag_existing_remediated_files_and_work_versions' do
    after { Rake::Task['pdf_remediation:flag_existing_remediated_files_and_work_versions'].reenable }

    context 'with matching and non-matching file types and filenames' do
      let!(:pdf_accessiblecopy_file_resource) do
        create(
          :file_resource,
          file_data: FileHelpers.pdf_data('AccessibleCopy_pdf.pdf')
        )
      end

      let!(:pdf_non_accessiblecopy_file_resource) do
        create(
          :file_resource,
          file_data: FileHelpers.pdf_data('regular_pdf.pdf')
        )
      end

      let!(:non_pdf_accessiblecopy_file_resource) do
        create(
          :file_resource,
          file_data: FileHelpers.text_data('AccessibleCopy_not_pdf.txt')
        )
      end

      let!(:work_version) do
        create(:work_version).tap do |version|
          create(:file_version_membership, work_version: version, file_resource: pdf_accessiblecopy_file_resource)
        end
      end

      it 'only flags PDF FileResources with AccessibleCopy_ filenames and their latest WorkVersions' do
        expect(pdf_accessiblecopy_file_resource.remediated_version).to be(false)
        expect(pdf_non_accessiblecopy_file_resource.remediated_version).to be(false)
        expect(non_pdf_accessiblecopy_file_resource.remediated_version).to be(false)
        expect(work_version.remediated_version).to be(false)

        expect {
          Rake::Task['pdf_remediation:flag_existing_remediated_files_and_work_versions'].invoke
        }.to change { pdf_accessiblecopy_file_resource.reload.remediated_version }.from(false).to(true)
          .and change { work_version.reload.remediated_version }.from(false).to(true)

        expect(pdf_non_accessiblecopy_file_resource.reload.remediated_version).to be(false)
        expect(non_pdf_accessiblecopy_file_resource.reload.remediated_version).to be(false)
      end
    end

    context 'when a FileResource has multiple WorkVersions' do
      let!(:file_resource) do
        create(
          :file_resource,
          file_data: FileHelpers.pdf_data('AccessibleCopy_multi_version.pdf')
        )
      end

      let!(:older_version) do
        create(:work_version, version_number: 1).tap do |version|
          create(:file_version_membership, work_version: version, file_resource: file_resource)
        end
      end

      let!(:newer_version) do
        create(:work_version, version_number: 2).tap do |version|
          create(:file_version_membership, work_version: version, file_resource: file_resource)
        end
      end

      it 'flags only the latest WorkVersion for each matching FileResource' do
        expect(older_version.remediated_version).to be(false)
        expect(newer_version.remediated_version).to be(false)

        Rake::Task['pdf_remediation:flag_existing_remediated_files_and_work_versions'].invoke

        expect(older_version.reload.remediated_version).to be(false)
        expect(newer_version.reload.remediated_version).to be(true)
      end
    end

    context 'with multiple matching FileResources' do
      let!(:file_resource1) do
        create(
          :file_resource,
          file_data: FileHelpers.pdf_data('AccessibleCopy_one.pdf')
        )
      end

      let!(:file_resource2) do
        create(
          :file_resource,
          file_data: FileHelpers.pdf_data('AccessibleCopy_two.pdf')
        )
      end

      let!(:work_version1) do
        create(:work_version).tap do |version|
          create(:file_version_membership, work_version: version, file_resource: file_resource1)
        end
      end

      let!(:work_version2) do
        create(:work_version).tap do |version|
          create(:file_version_membership, work_version: version, file_resource: file_resource2)
        end
      end

      it 'flags all matching FileResources and their latest WorkVersions' do
        expect(file_resource1.remediated_version).to be(false)
        expect(file_resource2.remediated_version).to be(false)
        expect(work_version1.remediated_version).to be(false)
        expect(work_version2.remediated_version).to be(false)

        Rake::Task['pdf_remediation:flag_existing_remediated_files_and_work_versions'].invoke

        expect(file_resource1.reload.remediated_version).to be(true)
        expect(file_resource2.reload.remediated_version).to be(true)
        expect(work_version1.reload.remediated_version).to be(true)
        expect(work_version2.reload.remediated_version).to be(true)
      end
    end
  end
end
