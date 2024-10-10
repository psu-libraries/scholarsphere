# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DepositorRequestService do
  describe '#request_action' do
    let(:work_version) { create :work_version, :able_to_be_published, published_date: pub_date }
    let(:pub_date) { '2024' }
    let(:curation_requested) { true }

    context 'when curation is requested' do
      before { allow(CurationTaskClient).to receive(:send_curation).with(work_version.id, requested: true, remediation_requested: false) }

      context 'when the work version is valid' do
        it 'sends it for curation' do
          described_class.new(work_version).request_action(curation_requested)
          expect(CurationTaskClient).to have_received(:send_curation).with(work_version.id, requested: true, remediation_requested: false)

          work_version.reload
          expect(work_version.draft_curation_requested).to be true
          expect(work_version.accessibility_remediation_requested).to be_nil
        end
      end

      context 'when the work version is invalid' do
        let(:pub_date) { 'not a date' }

        it 'does not send it for curation and raises invalid resource error' do
          expect { described_class.new(work_version).request_action(curation_requested) }.to raise_error(DepositorRequestService::InvalidResourceError)
          expect(CurationTaskClient).not_to have_received(:send_curation).with(work_version.id, requested: true, remediation_requested: false)

          work_version.reload
          expect(work_version.draft_curation_requested).to be false
          expect(work_version.accessibility_remediation_requested).to be_nil
        end
      end

      context 'when there is a Curation Task error' do
        before {
 allow(CurationTaskClient).to receive(:send_curation).with(work_version.id, requested: true,
                                                                            remediation_requested: false).and_raise(CurationTaskClient::CurationError) }

        it 'does not send it for remediation and raises request error' do
          expect { described_class.new(work_version).request_action(curation_requested) }.to raise_error(DepositorRequestService::RequestError)

          work_version.reload
          expect(work_version.draft_curation_requested).to be false
          expect(work_version.accessibility_remediation_requested).to be_nil
        end
      end
    end

    context 'when remediation is requested' do
      before { allow(CurationTaskClient).to receive(:send_curation).with(work_version.id, requested: false, remediation_requested: true) }

      let(:curation_requested) { false }

      context 'when the work version is valid' do
        it 'sends it for remediation' do
          described_class.new(work_version).request_action(curation_requested)
          expect(CurationTaskClient).to have_received(:send_curation).with(work_version.id, requested: false, remediation_requested: true)

          work_version.reload
          expect(work_version.draft_curation_requested).to be_nil
          expect(work_version.accessibility_remediation_requested).to be true
        end
      end

      context 'when the work version is invalid' do
        let(:pub_date) { 'not a date' }

        it 'does not send it for remediation and raises invalid resource error' do
          expect { described_class.new(work_version).request_action(curation_requested) }.to raise_error(DepositorRequestService::InvalidResourceError)
          expect(CurationTaskClient).not_to have_received(:send_curation).with(work_version.id, requested: false, remediation_requested: true)

          work_version.reload
          expect(work_version.draft_curation_requested).to be_nil
          expect(work_version.accessibility_remediation_requested).to be false
        end
      end

      context 'when there is a Curation Task error' do
        before {
 allow(CurationTaskClient).to receive(:send_curation).with(work_version.id, requested: false,
                                                                            remediation_requested: true).and_raise(CurationTaskClient::CurationError) }

        it 'does not send it for remediation and raises request error' do
          expect { described_class.new(work_version).request_action(curation_requested) }.to raise_error(DepositorRequestService::RequestError)

          work_version.reload
          expect(work_version.draft_curation_requested).to be_nil
          expect(work_version.accessibility_remediation_requested).to be false
        end
      end
    end
  end
end
