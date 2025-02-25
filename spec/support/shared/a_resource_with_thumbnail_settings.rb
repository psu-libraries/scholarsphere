# frozen_string_literal: true

RSpec.shared_examples 'a resource with thumbnail settings' do
  describe 'selecting the "Use Automatically Generated Image" radio buttonn' do
    context 'when no auto generated thumbnail exists for the resource' do
      before do
        visit Rails.application.routes.url_helpers.send(:"edit_dashboard_#{resource.class.to_s.downcase}_path", resource)
      end

      it '"Use Automatically Generated Image" radio button is disabled', :js do
        expect(page).to have_content('No Image').twice
        expect(page).to have_content(I18n.t!('helpers.hint.thumbnail_form.no_auto_generated_thumbnail'))
        expect(page).to have_css('input[id=thumbnail_form_thumbnail_selection_auto_generated][disabled=disabled]')
      end
    end

    context 'when auto generated thumbnail exists for the resource' do
      # This test will blow up if you `js: true` it.  Idk why.  Good thing it doesn't need js.
      before do
        allow_any_instance_of(resource.class).to receive(:auto_generated_thumbnail_url).and_return 'url.com/path/file'
        visit Rails.application.routes.url_helpers.send(:"edit_dashboard_#{resource.class.to_s.downcase}_path", resource)
      end

      it 'shows auto-generated image and the radio button is enabled' do
        expect(page).to have_no_content(I18n.t!('helpers.hint.thumbnail_form.no_auto_generated_thumbnail'))
        expect(page).to have_css('img[src="url.com/path/file"]')
        expect(page).to have_content('No Image').once
        expect(page)
          .to have_no_css('input[id=thumbnail_form_thumbnail_selection_auto_generated][disabled=disabled]')
        find_by_id('thumbnail_form_thumbnail_selection_auto_generated').set(true)
        click_button I18n.t!('dashboard.shared.thumbnail_form.submit_button')
        resource.reload
        expect(resource.thumbnail_selection).to eq ThumbnailSelections::AUTO_GENERATED
      end
    end
  end

  describe 'uploading thumbnail and selecting the "Use Uploaded Image" radio button' do
    before do
      visit Rails.application.routes.url_helpers.send(:"edit_dashboard_#{resource.class.to_s.downcase}_path", resource)
    end

    it 'uploads a thumbnail and selects "Use Uploaded Image" radio button', :js do
      expect(page).to have_content('No Image').twice
      expect(page).to have_css('input[id=thumbnail_form_thumbnail_selection_uploaded_image][disabled=disabled]')
      attach_file(Rails.root.join('spec', 'fixtures', 'image.png'))
      sleep 0.1
      expect(find_by_id('thumbnail_form_thumbnail_selection_uploaded_image').selected?).to eq true
      expect(page)
        .to have_no_css('input[id=thumbnail_form_thumbnail_selection_uploaded_image][disabled=disabled]')
      click_button I18n.t!('dashboard.shared.thumbnail_form.submit_button')
      expect(page).to have_content('No Image').once
      expect(page).to have_css('#uploaded-thumbnail-image')
      resource.reload
      expect(resource.thumbnail_upload.file_resource.file_data['metadata']['filename']).to eq 'image.png'
      expect(resource.thumbnail_selection).to eq ThumbnailSelections::UPLOADED_IMAGE
    end
  end

  describe 'selecting "Use Default Icon" radio button' do
    before do
      visit Rails.application.routes.url_helpers.send(:"edit_dashboard_#{resource.class.to_s.downcase}_path", resource)
    end

    it 'updated thumbnail selection' do
      find_by_id('thumbnail_form_thumbnail_selection_default_icon').set(true)
      click_button I18n.t!('dashboard.shared.thumbnail_form.submit_button')
      resource.reload
      expect(resource.thumbnail_selection).to eq ThumbnailSelections::DEFAULT_ICON
    end
  end
end
