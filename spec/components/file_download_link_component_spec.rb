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

  before do
    allow(file_resource).to receive(:file).and_return(file_double)
  end

  describe 'when the file is not an image' do
    let(:mime_type) { 'application/pdf' }

    it 'renders a download link with correct path and title' do
      render_inline(described_class.new(file_version_membership: file_version_membership))
      expect(page).to have_link(file_version_membership.title,
                                href: "/resources/#{resource.uuid}/downloads/#{file_version_membership.id}")
      expect(page).to have_css("a[aria-label='Download file: #{file_version_membership.title}']")
    end
  end

  context 'when the file is an image' do
    let(:mime_type) { 'image/png' }

    it 'renders a download link with correct path and title and alt text in the aria-label' do
      render_inline(described_class.new(file_version_membership: file_version_membership))
      expect(page).to have_link(file_version_membership.title,
                                href: "/resources/#{resource.uuid}/downloads/#{file_version_membership.id}")
      expect(page).to have_css("a[aria-label='Download file: #{file_version_membership.title}, an image of Test text']")
    end
  end
end
