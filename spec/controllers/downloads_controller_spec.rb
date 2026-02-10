# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DownloadsController do
  let(:user) { create(:user) }
  let(:admin_user) { create(:user, :admin) }
  let(:viewer_user) { create(:user, :viewer) }

  describe 'GET #content' do
    context 'when not signed in' do
      context 'when requesting a valid file from a work version' do
        let(:work_version) { create(:work_version, :published, :with_files, file_count: 2) }

        it 'redirects to a presigned S3 url' do
          get :content, params: { resource_id: work_version.uuid, id: work_version.file_version_memberships[0].id }
          expect(response).to be_redirect
        end

        it 'adds a view statistic record for the file resource' do
          expect {
            get :content, params: { resource_id: work_version.uuid, id: work_version.file_version_memberships[0].id }
          }.to change {
            ViewStatistic.where(
              resource_type: 'FileResource',
              resource_id: work_version.file_version_memberships[0].file_resource.id
            ).count
          }.from(0).to(1)
        end
      end

      context 'when requesting a non-existent file from a work version' do
        let(:work_version) { create(:work_version, :published, :with_files) }

        it do
          expect {
            get :content, params: { resource_id: work_version.uuid, id: 99 }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when requesting an unkown uuid' do
        it do
          expect {
            get :content, params: { resource_id: 'not-a-valid-uuid', id: 1 }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when requesting a file from an unauthorized draft version' do
        let(:work_version) { create(:work_version, :with_files) }

        it do
          expect {
            get :content, params: { resource_id: work_version.uuid, id: work_version.file_version_memberships[0].id }
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      context 'when requesting a file from a work' do
        let(:work) { create(:work, has_draft: false) }

        it do
          expect {
            get :content, params: { resource_id: work.uuid, id: 1 }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when a bot is requesting a file' do
        let(:work_version) { create(:work_version, :published, :with_files, file_count: 2) }
        let(:bot) { Browser.new('Bot') }

        before { allow(controller).to receive(:browser).and_return(bot) }

        it 'does NOT add a view statistic record for the file resource' do
          expect {
            get :content, params: { resource_id: work_version.uuid, id: work_version.file_version_memberships[0].id }
          }.not_to(
            change {
              ViewStatistic.where(
                resource_type: 'FileResource',
                resource_id: work_version.file_version_memberships[0].file_resource.id
              ).count
            }
          )
        end
      end
    end

    context 'when signed in as a non-privileged user' do
      before { sign_in user }

      context "when requesting a file from a draft version of another user's work" do
        let(:work_version) { create(:work_version, :with_files) }

        it do
          expect {
            get :content, params: { resource_id: work_version.uuid, id: work_version.file_version_memberships[0].id }
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      context "when requesting a file from a published version of another user's embargoed work" do
        let(:work_version) { create(:work_version, :published, :with_files, file_count: 2, work: work) }
        let(:work) { create(:work, embargoed_until: 1.week.from_now) }

        it do
          expect {
            get :content, params: { resource_id: work_version.uuid, id: work_version.file_version_memberships[0].id }
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end
    end

    context 'when signed in as an admin' do
      before { sign_in admin_user }

      context "when requesting a file from a draft version of another user's work" do
        let(:work_version) { create(:work_version, :with_files) }

        it 'redirects to a presigned S3 url' do
          get :content, params: { resource_id: work_version.uuid, id: work_version.file_version_memberships[0].id }
          expect(response).to be_redirect
        end
      end

      context "when requesting a file from a published version of another user's embargoed work" do
        let(:work_version) { create(:work_version, :published, :with_files, file_count: 2, work: work) }
        let(:work) { create(:work, embargoed_until: 1.week.from_now) }

        it 'redirects to a presigned S3 url' do
          get :content, params: { resource_id: work_version.uuid, id: work_version.file_version_memberships[0].id }
          expect(response).to be_redirect
        end
      end
    end

    context 'when signed in as a viewer' do
      before { sign_in viewer_user }

      context "when requesting a file from a draft version of another user's work" do
        let(:work_version) { create(:work_version, :with_files) }

        it 'redirects to a presigned S3 url' do
          get :content, params: { resource_id: work_version.uuid, id: work_version.file_version_memberships[0].id }
          expect(response).to be_redirect
        end
      end

      context "when requesting a file from a published version of another user's embargoed work" do
        let(:work_version) { create(:work_version, :published, :with_files, file_count: 2, work: work) }
        let(:work) { create(:work, embargoed_until: 1.week.from_now) }

        it 'redirects to a presigned S3 url' do
          get :content, params: { resource_id: work_version.uuid, id: work_version.file_version_memberships[0].id }
          expect(response).to be_redirect
        end
      end
    end
  end

  context 'when downloading a file twice' do
    let(:work_version) { create(:work_version, :published, :with_files, file_count: 2) }

    it 'counts the download once' do
      expect {
        2.times {
          get :content, params: { resource_id: work_version.uuid, id: work_version.file_version_memberships[0].id }
        }
      }.to(
        change {
          ViewStatistic.find_by(
            resource_type: 'FileResource',
            resource_id: work_version.file_version_memberships[0].file_resource_id
          )&.count || 0
        }.by(1)
      )
    end
  end

  context 'when "download" param is true' do
    let(:work_version) { create(:work_version, :published, :with_files, file_count: 2) }

    it 'uses "attachment" for the response content disposition' do
      get :content, params: { resource_id: work_version.uuid, id: work_version.file_version_memberships[0].id, download: true }
      expect(response.location).to include('response-content-disposition=attachment')
    end

    context 'when the download is able to be auto-remediated' do
      let(:pdf) { create(:file_resource, :pdf) }
      let(:work_version) { create(:work_version, :published, file_resources: [pdf]) }
      let(:service) { instance_double(PdfRemediation::AutoRemediateService, able_to_auto_remediate?: true, call: nil) }

      before { allow(PdfRemediation::AutoRemediateService).to receive(:new).and_return(service) }

      it 'calls AutoRemediationService' do
        get :content, params: { resource_id: work_version.uuid, id: work_version.file_version_memberships[0].id, download: true }
        expect(service).to have_received(:call)
      end
    end

    context 'when the download is not able to be auto-remediated' do
      let(:non_pdf) { create(:file_resource) }
      let(:work_version) { create(:work_version, :published, file_resources: [non_pdf]) }
      let(:service) { instance_double(PdfRemediation::AutoRemediateService, able_to_auto_remediate?: false, call: nil) }

      before { allow(PdfRemediation::AutoRemediateService).to receive(:new).and_return(service) }

      it 'does not enqueue an AutoRemediationJob' do
        get :content, params: { resource_id: work_version.uuid, id: work_version.file_version_memberships[0].id, download: true }
        expect(service).not_to have_received(:call)
      end
    end
  end

  context 'when "download" param is not present' do
    let(:work_version) { create(:work_version, :published, :with_files, file_count: 2) }
    let(:service) { instance_double(PdfRemediation::AutoRemediateService, able_to_auto_remediate?: true, call: nil) }

    before { allow(PdfRemediation::AutoRemediateService).to receive(:new).and_return(service) }

    it 'uses "inline" for the response content disposition' do
      get :content, params: { resource_id: work_version.uuid, id: work_version.file_version_memberships[0].id }
      expect(response.location).to include('response-content-disposition=inline')
      expect(service).not_to have_received(:call)
    end
  end
end
