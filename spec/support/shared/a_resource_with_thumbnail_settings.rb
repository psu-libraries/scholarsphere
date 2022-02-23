# frozen_string_literal: true

RSpec.shared_examples 'a resource with thumbnail settings' do
  describe 'toggling auto-generate thumbnail' do
    context 'when no auto generated thumbnail exists for the resource' do
      before do
        visit Rails.application.routes.url_helpers.send("edit_dashboard_#{resource.class.to_s.downcase}_path", resource)
      end

      it 'does not display auto-generate thumbnail section' do
        expect(page)
            .not_to have_content I18n.t!('dashboard.shared.auto_generate_thumbnail_form.explanation')
      end
    end

    context 'when auto generated thumbnail exists for the resource' do
      before do
        allow_any_instance_of(resource.class).to receive(:auto_generated_thumbnail_url).and_return 'url.com/path/file'
        visit Rails.application.routes.url_helpers.send("edit_dashboard_#{resource.class.to_s.downcase}_path", resource)
      end

      it 'works from the Settings page' do
        check(I18n.t!('dashboard.shared.auto_generate_thumbnail_form.explanation'), allow_label_click: true)
        expect(page).to have_content(I18n.t!('helpers.hint.thumbnail_form.auto_generate_thumbnail'))
        expect(page).to have_xpath('//img[@src="url.com/path/file"]')
        click_button I18n.t!('dashboard.shared.thumbnail_form.submit_button')
        expect(page)
            .to have_checked_field(I18n.t!('dashboard.shared.auto_generate_thumbnail_form.explanation'))

        resource.reload
        expect(resource.auto_generate_thumbnail).to eq true

        uncheck(I18n.t!('dashboard.shared.auto_generate_thumbnail_form.explanation'),
                allow_label_click: true)
        click_button I18n.t!('dashboard.shared.thumbnail_form.submit_button')
        expect(page)
            .to have_no_checked_field(I18n.t!('dashboard.shared.auto_generate_thumbnail_form.explanation'))

        resource.reload
        expect(resource.auto_generate_thumbnail).to eq false
      end
    end
  end

  describe 'uploading and deleting a thumbnail', js: true do
    before do
      visit Rails.application.routes.url_helpers.send("edit_dashboard_#{resource.class.to_s.downcase}_path", resource)
    end

    it 'uploads and deletes a thumbnail' do
      file_resource_count = FileResource.count
      within('.edit-thumbnail') do
        FeatureHelpers::DashboardForm.upload_file(Rails.root.join('spec', 'fixtures', 'image.png'))
      end
      expect { click_button I18n.t!('dashboard.shared.thumbnail_form.submit_button') }
          .to change(ThumbnailUpload, :count).by 1
      expect(ThumbnailUpload.last.file_resource.file_data['metadata']['filename']).to eq 'image.png'
      expect(ThumbnailUpload.last.resource).to eq resource

      expect(page).to have_content('Your uploaded thumbnail:')
      expect(page).to have_content('image.png')
      within('.edit-thumbnail') do
        accept_confirm do
          click_link('Remove')
        end
      end
      sleep 0.1

      expect(ThumbnailUpload.count).to eq 0
      expect(FileResource.count).to eq file_resource_count

      expect(page).not_to have_content('Your uploaded thumbnail:')
      expect(page).not_to have_content('image.png')
    end
  end
end
