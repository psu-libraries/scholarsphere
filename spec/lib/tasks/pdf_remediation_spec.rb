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

      let!(:work_version_w_pdf) do
        create(:work_version).tap do |version|
          create(:file_version_membership, work_version: version, file_resource: pdf_accessiblecopy_file_resource)
        end
      end

      let!(:work_version_w_non_pdf) do
        create(:work_version).tap do |version|
          create(:file_version_membership, work_version: version, file_resource: non_pdf_accessiblecopy_file_resource)
        end
      end

      it 'only flags FileResources with AccessibleCopy_ filenames and their latest WorkVersions' do
        expect(pdf_accessiblecopy_file_resource.remediated_version).to be(false)
        expect(pdf_non_accessiblecopy_file_resource.remediated_version).to be(false)
        expect(non_pdf_accessiblecopy_file_resource.remediated_version).to be(false)
        expect(work_version_w_pdf.remediated_version).to be(false)
        expect(work_version_w_non_pdf.remediated_version).to be(false)

        Rake::Task['pdf_remediation:flag_existing_remediated_files_and_work_versions'].invoke

        expect(pdf_accessiblecopy_file_resource.reload.remediated_version).to be(true)
        expect(work_version_w_pdf.reload.remediated_version).to be(true)

        expect(non_pdf_accessiblecopy_file_resource.reload.remediated_version).to be(true)
        expect(work_version_w_non_pdf.reload.remediated_version).to be(true)

        expect(pdf_non_accessiblecopy_file_resource.reload.remediated_version).to be(false)
      end
    end

    context 'when a FileResource has multiple WorkVersions' do
      let!(:work) { create(:work) }

      let!(:file_resource) do
        create(
          :file_resource,
          file_data: FileHelpers.pdf_data('AccessibleCopy_multi_version.pdf')
        )
      end

      let!(:older_version) do
        create(:work_version, work: work, version_number: 2).tap do |version|
          create(:file_version_membership, work_version: version, file_resource: file_resource)
        end
      end

      let!(:newer_version) do
        create(:work_version, work: work, version_number: 3).tap do |version|
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

  describe ':reset_failed_auto_remediation' do
    after { Rake::Task['pdf_remediation:reset_failed_auto_remediation'].reenable }

    let!(:in_range_file_resource) do
      create(
        :file_resource,
        remediation_job_uuid: 'job-in-range',
        auto_remediation_failed_at: Time.zone.parse('2026-03-10 12:00:00')
      )
    end

    let!(:out_of_range_file_resource) do
      create(
        :file_resource,
        remediation_job_uuid: 'job-out-of-range',
        auto_remediation_failed_at: Time.zone.parse('2026-04-15 09:00:00')
      )
    end

    let!(:older_version) do
      create(
        :work_version,
        auto_remediation_started_at: Time.zone.parse('2026-03-01 09:00:00')
      )
    end

    let!(:newer_version) do
      create(
        :work_version,
        auto_remediation_started_at: Time.zone.parse('2026-03-05 09:00:00')
      )
    end

    let!(:out_of_range_version) do
      create(
        :work_version,
        auto_remediation_started_at: Time.zone.parse('2026-04-01 10:00:00')
      )
    end

    before do
      create(:file_version_membership, file_resource: in_range_file_resource, work_version: older_version)
      create(:file_version_membership, file_resource: in_range_file_resource, work_version: newer_version)
      create(:file_version_membership, file_resource: out_of_range_file_resource, work_version: out_of_range_version)
    end

    it 'resets matching FileResources and only the most recent associated WorkVersion' do
      Rake::Task['pdf_remediation:reset_failed_auto_remediation'].invoke('2026-03-01', '2026-03-31')

      expect(in_range_file_resource.reload.auto_remediation_failed_at).to be_nil
      expect(in_range_file_resource.reload.remediation_job_uuid).to be_nil
      expect(older_version.reload.auto_remediation_started_at).not_to be_nil
      expect(newer_version.reload.auto_remediation_started_at).to be_nil

      expect(out_of_range_file_resource.reload.auto_remediation_failed_at).not_to be_nil
      expect(out_of_range_file_resource.reload.remediation_job_uuid).to eq('job-out-of-range')
      expect(out_of_range_version.reload.auto_remediation_started_at).not_to be_nil
    end
  end
end
