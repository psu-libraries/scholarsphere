# frozen_string_literal: true

RSpec.shared_examples 'a resource with thumbnail settings' do
  describe 'selecting Use Automatically Generated Image' do
    context 'when no auto generated thumbnail exists for the resource' do
      before do
        visit Rails.application.routes.url_helpers.send("edit_dashboard_#{resource.class.to_s.downcase}_path", resource)
      end

      it 'disables the Use Automatically Generated Image radio button is disabled', js: true do
        expect(page).to have_content('No Image').twice
        expect(page).to have_selector('input[id=thumbnail_form_thumbnail_selection_auto_generated][disabled=disabled]')
      end
    end

    context 'when auto generated thumbnail exists for the resource' do
      # This test will blow up if you `js: true` it.  Idk why.  Good thing it doesn't need js.
      before do
        allow_any_instance_of(resource.class).to receive(:auto_generated_thumbnail_url).and_return 'url.com/path/file'
        visit Rails.application.routes.url_helpers.send("edit_dashboard_#{resource.class.to_s.downcase}_path", resource)
      end

      it 'works from the Settings page' do
        expect(page).to have_content('No Image').once
        expect(page)
          .not_to have_selector('input[id=thumbnail_form_thumbnail_selection_auto_generated][disabled=disabled]')
        find('#thumbnail_form_thumbnail_selection_auto_generated').set(true)
        click_button I18n.t!('dashboard.shared.thumbnail_form.submit_button')
        resource.reload
        expect(resource.thumbnail_selection).to eq ThumbnailSelections::AUTO_GENERATED
        expect(page).to have_selector('img[src="url.com/path/file"]')
      end
    end
  end

  describe 'uploading thumbnail and selecting Use Uploaded Image' do
    before do
      visit Rails.application.routes.url_helpers.send("edit_dashboard_#{resource.class.to_s.downcase}_path", resource)
    end

    it 'uploads a thumbnail and selects Use Uploaded Image radio button', js: true do
      expect(page).to have_content('No Image').twice
      expect(page).to have_selector('input[id=thumbnail_form_thumbnail_selection_uploaded_image][disabled=disabled]')
      attach_file(Rails.root.join('spec', 'fixtures', 'image.png'))
      sleep 0.1
      expect(find('#thumbnail_form_thumbnail_selection_uploaded_image').selected?).to eq true
      expect(page)
        .not_to have_selector('input[id=thumbnail_form_thumbnail_selection_uploaded_image][disabled=disabled]')
      click_button I18n.t!('dashboard.shared.thumbnail_form.submit_button')
      expect(page).to have_content('No Image').once
      expect(page).to have_selector('#uploaded-thumbnail-image')
      resource.reload
      expect(resource.thumbnail_upload.file_resource.file_data['metadata']['filename']).to eq 'image.png'
      expect(resource.thumbnail_selection).to eq ThumbnailSelections::UPLOADED_IMAGE
    end
  end

  describe 'selecting Use Default Icon' do
    before do
      visit Rails.application.routes.url_helpers.send("edit_dashboard_#{resource.class.to_s.downcase}_path", resource)
    end

    it 'works from the Settings page' do
      find('#thumbnail_form_thumbnail_selection_default_icon').set(true)
      click_button I18n.t!('dashboard.shared.thumbnail_form.submit_button')
      resource.reload
      expect(resource.thumbnail_selection).to eq ThumbnailSelections::DEFAULT_ICON
    end
  end
end
