# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Public Resources' do
  describe 'given a work' do
    let(:work) { create(:work, has_draft: true, versions_count: 3) }

    let(:v1) { work.versions[0] }
    let(:v2) { work.versions[1] }
    let(:draft) { work.versions[2] }

    context 'when I am not logged in (i.e. as a public user)' do
      before do
        v2.update(description: 'This *has* [markdown](https://daringfireball.net/projects/markdown/)')
      end

      it 'displays the public resource page for the work' do
        visit resource_path(work.uuid)

        # @note There is some whitespace due to the :content_for block, but this is ultimately removed by the browser.
        expect(page.title).to include(v2.title)
        expect(page).to have_content(v2.title)

        # Spot check meta tags
        expect(page.find('meta[property="og:title"]', visible: false)[:content]).to eq v2.title
        expect(page.find('meta[property="og:description"]', visible: false)[:content]).to include(
          'This has markdown',
          v2.publisher_statement
        )
        # Below was failing in CI due to hostnames getting weird
        expect(page.find('meta[property="og:url"]', visible: false)[:content])
          .to match(resource_path(work.uuid)).and match(/^https?:/)
        expect(page.find('meta[name="citation_title"]', visible: false)[:content]).to eq v2.title
        expect(page.find('meta[name="citation_publication_date"]', visible: false)[:content])
          .to eq Date.edtf(v2.published_date).year.to_s
        all_authors = page.all(:css, 'meta[name="citation_author"]', visible: false)
        expect(all_authors.pluck(:content)).to match_array v2.creators.map(&:display_name)

        # Description is rendered as html
        expect(page).to have_link('markdown', href: 'https://daringfireball.net/projects/markdown/')

        ## Does not have edit controls
        within('header') do
          expect(page).to have_no_content(I18n.t!('resources.work_version.admin_edit_button', version: 'V2'))
          expect(page).to have_no_content(I18n.t!('resources.settings_button.text', type: 'Work'))
        end

        # Does not have a menu toggle button
        within('#top-section') do
          expect(page).to have_no_css('button')
        end

        ## Ensure we cannot navigate to the draft version
        within('.version-navigation .list-group') do
          expect(page).to have_no_content 'V3'
          expect(page).to have_no_content 'draft'
        end

        ## Ensure we do not see work history for draft version
        within('.version-timeline') do
          expect(page).to have_no_content 'Version 3'
          expect(page).to have_content 'Version 2'
        end

        ## Navigate to an old version
        within('.version-navigation .list-group') { click_on 'V1' }

        expect(page).to have_content(v1.title)
        expect(page).to have_content(I18n.t!('resources.old_version.message'))
      end

      it 'I can access a draft resource if I know the uuid' do
        visit resource_path(draft.uuid)

        expect(page.title).to include(draft.title)
        expect(page).to have_content(draft.title)

        ## Does not have edit controls
        within('header') do
          expect(page).to have_no_content(I18n.t!('resources.work_version.admin_edit_button', version: 'V3'))
          expect(page).to have_no_content(I18n.t!('resources.settings_button.text', type: 'Work'))
        end

        ## Does have draft in the navigation menu
        within('.version-navigation .list-group') do
          expect(page).to have_content 'V3'
        end

        ## Does have draft in work history
        within('.version-timeline') do
          expect(page).to have_content 'Version 3'
        end
      end

      context 'when the resource is in the data and code pathway' do
        let(:work) { create(:work, has_draft: true, versions_count: 3, work_type: 'dataset') }

        it 'displays a citation' do
          visit resource_path(work.uuid)

          expect(page).to have_content 'Citation'
          expect(page).to have_button('Copy Citation to Clipboard')
        end
      end

      context 'when the resource is not in the dataset pathway' do
        let(:work) { create(:work, has_draft: true, versions_count: 3, work_type: 'article') }

        it 'does not display a citation' do
          visit resource_path(work.uuid)

          expect(page).to have_no_content 'Citation'
          expect(page).to have_no_button('Copy Citation to Clipboard')
        end
      end
    end

    context 'when logged in as the resource owner', with_user: :user do
      let(:user) { work.depositor.user }

      before { visit resource_path(work.uuid) }

      context 'when no draft exists' do
        let(:work) { create(:work, has_draft: false, versions_count: 2) }

        it 'displays edit controls on the resource page' do
          expect(page).to have_content(v2.title) # Sanity

          within('header') do
            ## Edit Version button is hidden, but Update Work and Work Settings buttons are shown
            expect(page).to have_no_content(I18n.t!('resources.work_version.admin_edit_button', version: 'V2'))

            expect(page).to have_content(I18n.t!('resources.edit_button.text', type: 'Work'))
              .and have_content(I18n.t!('resources.settings_button.text', type: 'Work'))
          end

          ## Navigate to an old version
          within('.version-navigation .list-group') { click_on 'V1' }

          within('header') do
            ## Edit Version button is still hidden, and Update Work and Work Settings buttons are still shown
            expect(page).to have_no_content(I18n.t!('resources.work_version.admin_edit_button', version: 'V1'))

            expect(page).to have_content(I18n.t!('resources.edit_button.text', type: 'Work'))
              .and have_content(I18n.t!('resources.settings_button.text', type: 'Work'))
          end
        end
      end

      context 'when a draft exists' do
        let(:work) { create(:work, has_draft: true, versions_count: 3) }

        it 'displays edit controls on the resource page' do
          expect(page).to have_content(v2.title) # Sanity

          within('header') do
            ## Edit Version button is hidden, but Update Work and Work Settings buttons are shown
            expect(page).to have_no_content(I18n.t!('resources.work_version.admin_edit_button', version: 'V2'))

            expect(page).to have_content(I18n.t!('resources.edit_button.text', type: 'Work'))
              .and have_content(I18n.t!('resources.settings_button.text', type: 'Work'))
          end

          ## Does have draft in work history
          within('.version-timeline') do
            expect(page).to have_content 'Version 3'
          end

          ## Navigate to draft version
          within('.version-navigation .list-group') { click_on 'V3' }

          within('header') do
            ## Edit Version button is still hidden, and Update Work and Work Settings buttons are still shown
            expect(page).to have_no_content(I18n.t!('resources.work_version.admin_edit_button', version: 'V3'))

            expect(page).to have_content(I18n.t!('resources.edit_button.text', type: 'Work'))
              .and have_content(I18n.t!('resources.settings_button.text', type: 'Work'))
          end
        end
      end
    end

    context 'when logged in as an admin', with_user: :user do
      let(:user) { build(:user, :admin) }

      before do
        visit resource_path(work.uuid)
      end

      it 'displays the "Edit Work Version" button' do
        within ('header') do
          expect(page).to have_content(I18n.t!('resources.work_version.admin_edit_button', version: 'V2'))
        end
      end
    end

    context 'when the work is present in a collection' do
      let(:collection) { create(:collection) }
      let(:work) { create(:work, has_draft: false, collections: [collection]) }

      it 'displays information about the collection' do
        visit resource_path(work.uuid)

        expect(page).to have_link(collection.title)
      end
    end

    context 'when work has a thumbnail' do
      let(:collection) { create(:collection) }

      context 'when work#default_thumbnail? is true' do
        before do
          allow_any_instance_of(Work).to receive(:default_thumbnail?).and_return true
          allow_any_instance_of(ThumbnailComponent).to receive(:thumbnail_url).and_return 'url.com/path/file'
          visit resource_path(work.uuid)
        end

        it 'does not display thumbnail' do
          expect(page).to have_no_css("img[src='url.com/path/file']")
          expect(page).to have_no_css('.thumbnail-card')
        end
      end

      context 'when work#default_thumbnail? is false' do
        before do
          allow_any_instance_of(Work).to receive(:default_thumbnail?).and_return false
          allow_any_instance_of(ThumbnailComponent).to receive(:thumbnail_url).and_return 'url.com/path/file'
          visit resource_path(work.uuid)
        end

        it 'displays the thumbnail' do
          expect(page).to have_css("img[src='url.com/path/file']")
          expect(page).to have_css('.thumbnail-card')
        end
      end
    end

    context 'when work does not have a thumbnail' do
      let(:work) { create(:work) }

      before do
        allow_any_instance_of(ThumbnailComponent).to receive(:thumbnail_url).and_return nil
      end

      context 'when work#default_thumbnail? is true' do
        before do
          allow_any_instance_of(Work).to receive(:default_thumbnail?).and_return true
          visit resource_path(work.uuid)
        end

        it 'does not display thumbnail' do
          expect(page).to have_no_css('.thumbnail-image')
        end
      end

      context 'when work#default_thumbnail? is false' do
        before do
          allow_any_instance_of(Work).to receive(:default_thumbnail?).and_return false
          visit resource_path(work.uuid)
        end

        it 'does not display thumbnail' do
          expect(page).to have_no_css('.thumbnail-image')
        end
      end
    end
  end

  describe 'a collection' do
    context 'when it does NOT have a DOI' do
      let(:collection) do
        create(:collection,
               :with_complete_metadata,
               works: [work],
               description: 'This *has* [markdown](https://daringfireball.net/projects/markdown/)')
      end

      let(:work) { build(:work, has_draft: false, versions_count: 1) }

      it 'displays the public resource page for the collection' do
        visit resource_path(collection.uuid)

        expect(page.title).to include(collection.title)

        # Spot check meta tags
        expect(page.find('meta[property="og:title"]', visible: false)[:content]).to eq collection.title
        expect(page.find('meta[property="og:description"]', visible: false)[:content]).to eq 'This has markdown'
        # Below was failing in CI due to hostnames getting weird
        expect(page.find('meta[property="og:url"]', visible: false)[:content])
          .to match(resource_path(collection.uuid)).and match(/^https?:/)

        expect(page).to have_css('h1', text: collection.title)
        expect(page).to have_link('markdown', href: 'https://daringfireball.net/projects/markdown/')
        expect(page).to have_content work.latest_published_version.title

        within('td.collection-title') do
          expect(page).to have_content(collection.title)
        end
      end
    end

    context 'when it has a DOI' do
      let(:collection) { create(:collection, :with_complete_metadata, :with_a_doi, works: [work]) }
      let(:work) { build(:work, has_draft: false, versions_count: 1) }

      it 'displays the public resource page for the collection' do
        visit resource_path(collection.uuid)

        expect(page).to have_css('h1', text: collection.title)
        expect(page).to have_content collection.description
        expect(page).to have_content work.latest_published_version.title

        within('td.collection-display-doi') do
          expect(page).to have_content(collection.doi)
        end
      end
    end

    context 'when logged in as the resource owner', with_user: :user do
      let(:collection) { create(:collection) }
      let(:user) { collection.depositor.user }

      it 'displays edit controls on the resource page' do
        visit resource_path(collection.uuid)

        expect(page.title).to include(collection.title)

        within('header') do
          expect(page).to have_content(I18n.t!('resources.edit_button.text', type: 'Collection'))
        end
      end
    end

    context 'when collection has a thumbnail' do
      let(:collection) { create(:collection) }

      context 'when collection#default_thumbnail? is true' do
        before do
          allow_any_instance_of(Collection).to receive(:default_thumbnail?).and_return true
          allow_any_instance_of(ThumbnailComponent).to receive(:thumbnail_url).and_return 'url.com/path/file'
          visit resource_path(collection.uuid)
        end

        it 'does not display thumbnail' do
          expect(page).to have_no_css("img[src='url.com/path/file']")
          expect(page).to have_no_css('.thumbnail-card')
        end
      end

      context 'when collection#default_thumbnail? is false' do
        before do
          allow_any_instance_of(Collection).to receive(:default_thumbnail?).and_return false
          allow_any_instance_of(ThumbnailComponent).to receive(:thumbnail_url).and_return 'url.com/path/file'
          visit resource_path(collection.uuid)
        end

        it 'displays the thumbnail' do
          expect(page).to have_css("img[src='url.com/path/file']")
          expect(page).to have_css('.thumbnail-card')
        end
      end
    end

    context 'when collection does not have a thumbnail' do
      let(:collection) { create(:collection) }

      before do
        allow_any_instance_of(ThumbnailComponent).to receive(:thumbnail_url).and_return nil
      end

      context 'when collection#default_thumbnail? is true' do
        before do
          allow_any_instance_of(Collection).to receive(:default_thumbnail?).and_return true
          visit resource_path(collection.uuid)
        end

        it 'does not display thumbnail' do
          expect(page).to have_no_css('.thumbnail-image')
        end
      end

      context 'when collection#default_thumbnail? is false' do
        before do
          allow_any_instance_of(Collection).to receive(:default_thumbnail?).and_return false
          visit resource_path(collection.uuid)
        end

        it 'does not display thumbnail' do
          expect(page).to have_no_css('.thumbnail-image')
        end
      end
    end
  end
end
