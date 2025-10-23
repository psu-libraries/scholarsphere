# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BuildAutoRemediatedWorkVersion do
  let!(:user) { create(:user, access_id: 'test', email: 'test@psu.edu') }
  let!(:work) { create(:work, depositor: user.actor) }
  let!(:file_resource) { create(:file_resource, remediation_job_uuid: SecureRandom.uuid) }
  let!(:wv_being_remediated) { create(:work_version,
                                      :published,
                                      auto_remediation_started_at: Time.current,
                                      work: work,
                                      file_resources: [file_resource]) }
  let(:remediated_url) { 'https://example.com/remediated.pdf' }
  let(:lib_answers) { LibanswersApiService.new }

  describe '.call' do
    before do
      allow(lib_answers).to receive(:admin_create_ticket)
      allow(LibanswersApiService).to receive(:new).and_return(lib_answers)
    end

    context 'when a newer published version exists' do
      let!(:existing_auto) { create(:work_version,
                                    :draft, auto_remediated_version: true,
                                            work: work,
                                            file_resources: [file_resource]) }

      before do
        create(:work_version,
               :published,
               work: work,
               file_resources: [file_resource])
      end

      it 'destroys any existing auto-remediated version and raises NotNewestReleaseError' do
        expect {
          described_class.call(file_resource, remediated_url)
        }.to raise_error(BuildAutoRemediatedWorkVersion::NotNewestReleaseError)
        expect(WorkVersion).not_to exist(existing_auto.id)
      end
    end

    context 'when the work version being remediated is the latest published version' do
      context 'when no auto-remediated work version exists after the one being remediated' do
        context 'when no remaining remediation jobs' do
          it 'builds a new work version, attaches the remediated file, and publishes' do
            allow(Down).to receive(:download).with(remediated_url).and_return(Tempfile.new('remediated'))
            wv_count_before = WorkVersion.count

            result = described_class.call(file_resource, remediated_url)
            expect(WorkVersion.count).to eq(wv_count_before + 1)
            expect(FileResource).to exist(file_resource.id)
            expect(FileVersionMembership.find_by(work_version: result, file_resource: file_resource)).to be_nil
            expect(WorkVersion.find(result.id).file_resources.where(auto_remediated_version: true).count).to eq(1)
            expect(result.external_app).to eq(ExternalApp.pdf_accessibility_api)
            expect(result).to be_published
          end

          it 'calls the Libanswers service with an admin curation ticket' do
            allow(Down).to receive(:download).with(remediated_url).and_return(Tempfile.new('remediated'))
            result = described_class.call(file_resource, remediated_url)
            expect(lib_answers).to have_received(:admin_create_ticket).with(result.work.id, 'work_remediation')
          end
        end

        context 'when there are remaining remediation jobs' do
          let!(:other_file_resource) { create(:file_resource, remediation_job_uuid: SecureRandom.uuid) }

          before do
            wv_being_remediated.file_resources << other_file_resource
            wv_being_remediated.save!
          end

          it 'builds a new work version, attaches the remediated file, but does not publish it' do
            allow(Down).to receive(:download).with(remediated_url).and_return(Tempfile.new('remediated'))
            wv_count_before = WorkVersion.count

            result = described_class.call(file_resource, remediated_url)

            expect(WorkVersion.count).to eq(wv_count_before + 1)
            expect(FileResource).to exist(file_resource.id)
            expect(FileVersionMembership.find_by(work_version: result, file_resource: file_resource)).to be_nil
            expect(WorkVersion.find(result.id).file_resources.where(auto_remediated_version: true).count).to eq(1)
            expect(result.external_app).to eq(ExternalApp.pdf_accessibility_api)
            expect(result).to be_draft
          end

          it 'does not call the Libanswers service' do
            allow(Down).to receive(:download).with(remediated_url).and_return(Tempfile.new('remediated'))
            result = described_class.call(file_resource, remediated_url)
            expect(lib_answers).not_to have_received(:admin_create_ticket).with(result.work.id, 'work_remediation')
          end
        end
      end

      context 'when an auto-remediated work version already exists after the one being remediated' do
        let!(:existing_auto_wv) { BuildNewWorkVersion.call(wv_being_remediated) }

        before do
          existing_auto_wv.auto_remediated_version = true
          existing_auto_wv.external_app = ExternalApp.pdf_accessibility_api
          existing_auto_wv.save!
        end

        context 'when no remaining remediation jobs' do
          it 'attaches the remediated file to the existing auto-remediated work version, and publishes' do
            allow(Down).to receive(:download).with(remediated_url).and_return(Tempfile.new('remediated'))
            wv_count_before = WorkVersion.count

            result = described_class.call(file_resource, remediated_url)

            expect(WorkVersion.count).to eq(wv_count_before)
            expect(FileResource).to exist(file_resource.id)
            expect(FileVersionMembership.find_by(work_version: result, file_resource: file_resource)).to be_nil
            expect(WorkVersion.find(result.id).file_resources.where(auto_remediated_version: true).count).to eq(1)
            expect(result.external_app).to eq(ExternalApp.pdf_accessibility_api)
            expect(result).to be_published
          end

          it 'calls the Libanswers service with an admin curation ticket' do
            allow(Down).to receive(:download).with(remediated_url).and_return(Tempfile.new('remediated'))
            result = described_class.call(file_resource, remediated_url)
            expect(lib_answers).to have_received(:admin_create_ticket).with(result.work.id, 'work_remediation')
          end
        end

        context 'when there are remaining remediation jobs' do
          let!(:other_file_resource) { create(:file_resource, remediation_job_uuid: SecureRandom.uuid) }

          before do
            existing_auto_wv.file_resources << other_file_resource
            existing_auto_wv.save!
          end

          it 'attaches the remediated file to the existing auto-remediated work version, but does not publish it' do
            allow(Down).to receive(:download).with(remediated_url).and_return(Tempfile.new('remediated'))
            wv_count_before = WorkVersion.count

            result = described_class.call(file_resource, remediated_url)

            expect(WorkVersion.count).to eq(wv_count_before)
            expect(FileResource).to exist(file_resource.id)
            expect(FileVersionMembership.find_by(work_version: result, file_resource: file_resource)).to be_nil
            expect(WorkVersion.find(result.id).file_resources.where(auto_remediated_version: true).count).to eq(1)
            expect(result.external_app).to eq(ExternalApp.pdf_accessibility_api)
            expect(result).to be_draft
          end

          it 'does not call the Libanswers service' do
            allow(Down).to receive(:download).with(remediated_url).and_return(Tempfile.new('remediated'))
            result = described_class.call(file_resource, remediated_url)
            expect(lib_answers).not_to have_received(:admin_create_ticket).with(result.work.id, 'work_remediation')
          end
        end
      end
    end
  end
end
