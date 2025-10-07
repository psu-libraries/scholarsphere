# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileDownloadLinkComponent, type: :component do
  let!(:resource) { create(:work_version) }
  let!(:file_resource) { create(:file_resource) }
  let(:file_double) { instance_double(FileUploader::UploadedFile, metadata: { 'alt_text' => 'Test text' },
                                                                  mime_type: mime_type) }
  let!(:file_version_membership) { create(:file_version_membership,
                                          file_resource: file_resource,
                                          work_version: resource) }
  let(:user) { build(:user) }
  let(:mock_controller) do
    instance_double('ApplicationController', current_user: user, controller_name: 'application')
  end
  let(:mock_helpers) { double('helpers', current_user: user) }

  before do
    allow(file_resource).to receive(:file).and_return(file_double)
    allow_any_instance_of(described_class).to receive(:controller).and_return(mock_controller)
    allow_any_instance_of(described_class).to receive(:helpers).and_return(mock_helpers)
  end

  describe 'when the file is not an image' do
    let(:mime_type) { 'application/pdf' }

    it 'renders a download link with correct path and title' do
      render_inline(described_class.new(file_version_membership: file_version_membership))
      expect(page).to have_link(I18n.t!('resources.download',
                                        name: file_version_membership.title),
                                href: "/resources/#{resource.uuid}/downloads/#{file_version_membership.id}?download=true")
      expect(page).to have_link(I18n.t!('resources.view',
                                        name: file_version_membership.title),
                                href: "/resources/#{resource.uuid}/downloads/#{file_version_membership.id}?download=false")
      expect(page).to have_css("a[aria-label='Download file: #{file_version_membership.title}']")
      expect(page).to have_css("a[aria-label='View file: #{file_version_membership.title}']")
    end
  end

  context 'when the file is an image' do
    let(:mime_type) { 'image/png' }

    it 'renders a download link with correct path and title and alt text in the aria-label' do
      render_inline(described_class.new(file_version_membership: file_version_membership))
      expect(page).to have_link(I18n.t!('resources.download',
                                        name: file_version_membership.title),
                                href: "/resources/#{resource.uuid}/downloads/#{file_version_membership.id}?download=true")
      expect(page).to have_link(I18n.t!('resources.view',
                                        name: file_version_membership.title),
                                href: "/resources/#{resource.uuid}/downloads/#{file_version_membership.id}?download=false")
      expect(page).to have_css("a[aria-label='Download file: #{file_version_membership.title}, an image of Test text']")
      expect(page).to have_css("a[aria-label='View file: #{file_version_membership.title}, an image of Test text']")
    end
  end

  context 'when the file is able to auto remediate' do
    let(:mime_type) { 'application/pdf' }

    it 'shows the remediation alert' do
      allow_any_instance_of(AutoRemediateService).to receive(:able_to_auto_remediate?).and_return(true)
      render_inline(described_class.new(file_version_membership: file_version_membership))
      expect(page).to have_css('[data-popup-show-alert="true"]')
      expect(page).to have_css('#remediationPopup')
    end
  end

  context 'when the file is not able to auto remediate' do
    let(:mime_type) { 'application/pdf' }

    it 'does not show the remediation alert' do
      allow_any_instance_of(AutoRemediateService).to receive(:able_to_auto_remediate?).and_return(false)
      render_inline(described_class.new(file_version_membership: file_version_membership))
      expect(page).to have_css('[data-popup-show-alert="false"]')
      expect(page).to have_css('#remediationPopup')
    end
  end
end
