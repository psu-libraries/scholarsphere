# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutoRemediateService do
  describe '#call' do
    let(:work_version) { create(:work_version, :published, file_resources: [pdf1, pdf2, non_pdf, pdf3]) }
    let(:pdf1) { create(:file_resource, :pdf) }
    let(:pdf2) { create(:file_resource, :pdf) }
    let(:non_pdf) { create(:file_resource) }
    let(:pdf3) { create(:file_resource, :pdf, remediation_job_uuid: 'existing_uuid') }

    before { allow(AutoRemediationJob).to receive(:perform_later) }

    it 'enqueues an AutoRemediationJob for each PDF file resource without an existing remediation_job_uuid' do
      described_class.new(work_version.id, false, true).call
      expect(AutoRemediationJob).to have_received(:perform_later).with(pdf1.id)
      expect(AutoRemediationJob).to have_received(:perform_later).with(pdf2.id)
      expect(AutoRemediationJob).not_to have_received(:perform_later).with(non_pdf.id)
      expect(AutoRemediationJob).not_to have_received(:perform_later).with(pdf3.id)
    end
  end

  describe '#able_to_auto_remediate?' do
    context 'when the work version is the latest published version' do
      context 'when remediation has not been started' do
        context 'when there is no remediated version' do
          let(:work_version) { create(:work_version, :published) }

          context 'when the download is a PDF' do
            context 'when the user is not an admin' do
              context 'when the work is not under manual review' do
                it 'returns true' do
                  expect(described_class.new(work_version.id, false, true).able_to_auto_remediate?).to be true
                end
              end

              context 'when the work is under manual review' do
                before { work_version.work.update(under_manual_review: true) }

                it 'returns false' do
                  expect(described_class.new(work_version.id, false, true).able_to_auto_remediate?).to be false
                end
              end
            end

            context 'when the user is an admin' do
              it 'returns false' do
                expect(described_class.new(work_version.id, true, true).able_to_auto_remediate?).to be false
              end
            end
          end

          context 'when the download is not a PDF' do
            it 'returns false' do
              expect(described_class.new(work_version.id, false, false).able_to_auto_remediate?).to be false
            end
          end
        end

        context 'when there is a remediated version' do
          let(:work_version) { create(:work_version, :published, auto_remediated_version: true) }

          it 'returns false' do
            expect(described_class.new(work_version.id, false, true).able_to_auto_remediate?).to be false
          end
        end
      end

      context 'when remediation has been started' do
        let(:work_version) { create(:work_version, :published, auto_remediation_started_at: 1.hour.ago) }

        it 'returns false' do
          expect(described_class.new(work_version.id, false, true).able_to_auto_remediate?).to be false
        end
      end
    end

    context 'when the work version is not the latest published version' do
      let(:work_version) { create(:work_version, :draft) }

      it 'returns false' do
        expect(described_class.new(work_version.id, false, true).able_to_auto_remediate?).to be false
      end
    end
  end
end
