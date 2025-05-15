# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurationSyncService do
  describe '.sync' do
    context 'when the latest work version for curation is found in tasks table' do
      let(:work_version1) { build(:work_version,
                                  work: nil,
                                  aasm_state: 'published',
                                  draft_curation_requested: nil,
                                  published_at: Time.new(2024, 3, 10, 10, 30, 0))
      }
      let(:work_version2) { build(:work_version,
                                  work: nil,
                                  aasm_state: 'draft',
                                  draft_curation_requested: true,
                                  published_at: nil)
      }
      let(:work) { create(:work, versions: [work_version1, work_version2]) }
      let(:task) { instance_double 'Submission',
                                   fields: { 'ID' => work_version2.uuid },
                                   id: 'table_id_1'}

      before do
        allow(CurationTaskClient).to receive(:send_curation).with(work.id)
        allow(CurationTaskClient).to receive(:find_all).with(work.id).and_return([task])
        allow(task).to receive(:[]).and_return(work_version2.uuid)
      end

      it 'does not send another curation' do
        expect(CurationTaskClient).not_to receive(:send_curation).with(work_version2.id)

        described_class.new(work).sync
      end
    end

    context 'when there is an error' do
      let(:work_version1) { build(:work_version,
                                  work: nil,
                                  aasm_state: 'draft',
                                  draft_curation_requested: true,
                                  published_at: Time.new(2024, 3, 10, 10, 30, 0))
      }
      let(:work) { create(:work, versions: [work_version1]) }

      before do
        allow(CurationTaskClient).to receive(:find_all).with(work.id).and_raise(CurationTaskClient::CurationError, message)
      end

      context 'when it is not a 5XX error' do
        let(:message) { 'HTTP 422: UNKNOWN_FIELD_NAME: Unknown field name: \"Label\"' }

        it 'does not retry and logs the error' do
          expect(CurationTaskClient).to receive(:find_all).once
          expect(Rails.logger).to receive(:error).once

          described_class.new(work).sync
        end
      end

      context 'when it is a 5XX error' do
        let(:message) { 'HTTP 503: Service Unavailable' }

        it 'retries and logs error if it persists' do
          expect(CurationTaskClient).to receive(:find_all).exactly(3).times
          expect(Rails.logger).to receive(:error).once

          described_class.new(work).sync
        end
      end
    end

    context 'when the latest work version for curation is not found in tasks table', versioning: true do
      let(:work_version1) { build(:work_version,
                                  work: nil,
                                  aasm_state: 'published',
                                  draft_curation_requested: nil,
                                  published_at: Time.new(2024, 2, 10, 10, 30, 0))
      }
      let(:work_version2) { build(:work_version,
                                  work: nil,
                                  aasm_state: 'published',
                                  draft_curation_requested: true,
                                  published_at: Time.new(2024, 3, 10, 10, 30, 0))
      }
      let(:work_version3) { build(:work_version,
                                  work: nil,
                                  aasm_state: 'draft',
                                  draft_curation_requested: nil,
                                  published_at: nil)
      }
      let(:work) { create(:work, versions: [work_version1, work_version2, work_version3]) }
      let(:task1) { instance_double 'Submission',
                                    fields: { 'ID' => work_version1.uuid },
                                    id: 'table_id_1'}

      before do
        allow(CurationTaskClient).to receive(:send_curation).with(work.id, updated_version: true)
        allow(CurationTaskClient).to receive(:find_all).with(work.id).and_return([task1])
        allow(task1).to receive(:[]).and_return(work_version1.uuid)
      end

      it 'sends current version for curation with Updated Version label' do
        expect(CurationTaskClient).to receive(:send_curation).with(work_version2.id, updated_version: true)
        expect(CurationTaskClient).not_to receive(:send_curation).with(work_version1.id)
        expect(CurationTaskClient).not_to receive(:send_curation).with(work_version3.id)

        described_class.new(work).sync
      end

      context 'when the latest work version was created by an admin' do
        # The latest published work_version must be saved, so that PaperTrail can track the changes
        let(:work_version2) { create(:work_version, :published, title: 'Title with-dash') }
        let(:admin)  { create(:user, :admin) }

        it 'does not send current version for curation' do
          PaperTrail.request.whodunnit = admin.id
          work_version2.update(published_at: Time.new(2024, 5, 10, 10, 30, 0))
          expect(CurationTaskClient).not_to receive(:send_curation).with(work_version2.id, updated_version: true)
          described_class.new(work).sync
        end
      end
    end
  end
end
