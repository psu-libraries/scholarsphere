# frozen_string_literal: true

require 'rails_helper'
require 'support/vcr'

RSpec.describe 'Submitting the Contact Depositor form', :vcr, type: :feature, with_user: :user do
  let(:depositor) { create :user, email: 'test123@psu.edu', access_id: 'test123' }
  let(:work) { create :work, versions_count: 1, has_draft: false, depositor: depositor.actor }
  let(:message) { Faker::Lorem.paragraph }

  context 'when admin user' do
    let(:user) { create :user, :admin }
    before do
      visit admin_contact_depositors_path(id: work.id)
    end

    describe 'navigating to form, filling out required fields, and submitting the form' do
      context 'when no error is raised' do
        it 'prepopulates fields in form and redirects to the libanswers ticket after submission' do
          expect(find('#admin_contact_depositor_send_to_name').value).to eq work.depositor.display_name
          expect(find('#admin_contact_depositor_send_to_email').value).to eq work.depositor.email
          expect(find('#admin_contact_depositor_subject').value).to be_blank
          expect(find('#admin_contact_depositor_message').value).to be_blank
          fill_in('admin_contact_depositor_subject', with: 'Test Subject')
          fill_in('admin_contact_depositor_message', with: message)
          click_on 'Send'
        rescue ActionController::RoutingError
          # This is a bit unconventional.  Since clicking the "Send" button will redirect to an external site,
          # a routing error will be raised in the test env.  Rescue it and check the correct redirect location
          expect(page.driver.browser.last_response['Location']).to eq 'https://psu.libanswers.com/admin/ticket?qid=13162084'
        end
      end

      context 'when the data submitted in the form is not valid' do
        it 'renders the form and presents a flash message with the error message' do
          fill_in('admin_contact_depositor_send_to_email', with: 'notavalidemail')
          fill_in('admin_contact_depositor_subject', with: 'Test Subject')
          fill_in('admin_contact_depositor_message', with: message)
          click_on 'Send'
          expect(page).to have_content 'Send to email is invalid'
          expect(page).to have_current_path admin_contact_depositors_path(id: work.id), ignore_query: true
          expect(find('#admin_contact_depositor_send_to_name').value).to eq work.depositor.display_name
          expect(find('#admin_contact_depositor_send_to_email').value).to eq 'notavalidemail'
          expect(find('#admin_contact_depositor_subject').value).to eq 'Test Subject'
          expect(find('#admin_contact_depositor_message').value).to eq message
        end
      end

      context 'when the libanswers api service raises an error' do
        before do
          allow(LibanswersApiService).to receive(:new).and_raise LibanswersApiService::LibanswersApiError, 'Error Message'
        end

        it 'renders the form and presents a flash message with the error message' do
          fill_in('admin_contact_depositor_subject', with: 'Test Subject')
          fill_in('admin_contact_depositor_message', with: message)
          click_on 'Send'
          expect(page).to have_content 'Error Message'
          expect(page).to have_current_path admin_contact_depositors_path(id: work.id), ignore_query: true
          expect(find('#admin_contact_depositor_send_to_name').value).to eq work.depositor.display_name
          expect(find('#admin_contact_depositor_send_to_email').value).to eq work.depositor.email
          expect(find('#admin_contact_depositor_subject').value).to eq 'Test Subject'
          expect(find('#admin_contact_depositor_message').value).to eq message
        end
      end
    end
  end

  context 'when regular user' do
    let(:user) { create :user }

    it 'does not allow user to access the contact form' do
      expect { visit admin_contact_depositors_path(id: work.id) }.to raise_error ActionController::RoutingError
    end
  end
end
