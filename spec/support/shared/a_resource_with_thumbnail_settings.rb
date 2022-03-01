# frozen_string_literal: true

RSpec.shared_examples 'a resource with thumbnail settings' do
  describe 'selecting Use Automatically Generated Image' do
    context 'when no auto generated thumbnail exists for the resource' do
      before do
        visit Rails.application.routes.url_helpers.send("edit_dashboard_#{resource.class.to_s.downcase}_path", resource)
      end

      it 'the Use Automatically Generated Image radio button is disabled' do
      end
    end

    context 'when auto generated thumbnail exists for the resource' do
      it 'works from the Settings page' do
      end
    end
  end

  describe 'uploading thumbnail and selecting Use Uploaded Image', js: true do
    before do
      visit Rails.application.routes.url_helpers.send("edit_dashboard_#{resource.class.to_s.downcase}_path", resource)
    end

    it 'uploads and thumbnail and selects Use Uploaded Image radio button' do
    end
  end

  describe 'selecting Use Default Icon' do
    it 'works from the Settings page' do
    end
  end
end
