# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard File Management', with_user: :user do
  let(:work_version) { create :work_version, :draft, :with_files }
  let(:user) { work_version.depositor.user }
  let(:file_membership) { work_version.file_version_memberships.first }

  it 'renames a file without JavaScript enabled' do
    visit(dashboard_work_version_file_list_path(work_version))

    within "##{dom_id(file_membership)}" do
      click_link I18n.t('dashboard.file_list.edit.rename')
    end

    edited_filename = "EDITED#{File.extname(file_membership.title)}"
    fill_in FileVersionMembership.human_attribute_name('title'), with: edited_filename
    click_button I18n.t('dashboard.file_version_memberships.edit.save')

    expect(file_membership.reload.title).to eq edited_filename

    within "##{dom_id(file_membership)}" do
      expect(page).to have_content edited_filename
    end
  end

  it 'renames a file inline with JavaScript', js: true do
    visit(dashboard_work_version_file_list_path(work_version))

    edited_filename = "EDITED#{File.extname(file_membership.title)}"

    within "##{dom_id(file_membership)}" do
      click_link I18n.t('dashboard.file_list.edit.rename')
      fill_in FileVersionMembership.human_attribute_name('title'), with: edited_filename
      click_button I18n.t('dashboard.file_version_memberships.edit.save')

      # Note, there's an implicit trick here to make Capybara wait for AJAX
      expect(find('.filename')).to have_content edited_filename
    end

    expect(file_membership.reload.title).to eq edited_filename
  end

  it 'deletes a file' do
    visit(dashboard_work_version_file_list_path(work_version))

    within "##{dom_id(file_membership)}" do
      click_link I18n.t('dashboard.file_list.edit.delete')
    end

    expect { file_membership.reload }.to raise_error(ActiveRecord::RecordNotFound)

    expect(page).not_to have_content file_membership.title
  end
end
