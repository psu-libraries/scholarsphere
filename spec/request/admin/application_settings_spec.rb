 # frozen_string_literal: true

 require 'rails_helper'

 RSpec.describe 'Application Settings', type: :request do
   before { sign_in user }

   describe 'GET /admin/application_settings' do
     context 'with a non-admin user' do
       let(:user) { create(:user) }

       specify do
        get admin_application_settings_path
        expect(response).to have_http_status(:not_found)
       end
     end

     context 'with an admin user' do
       let(:user) { create(:user, :admin) }

       specify do
         get admin_application_settings_path
         expect(response).to be_successful
       end
     end
   end

   describe 'PATCH /admin/application_settings' do
     let(:new_attributes) { attributes_for(:application_setting) }

     let(:invalid_attributes) do
       { foo: 'bar' }
     end

     context 'with a non-admin user' do
       let(:user) { create(:user) }

       specify do
        patch admin_application_settings_url, params: { application_setting: new_attributes }
        expect(response).to have_http_status(:not_found)
       end
     end

     context 'with valid parameters' do
       let(:user) { create(:user, :admin) }

       it 'updates the requested application_setting' do
         patch admin_application_settings_url, params: { application_setting: new_attributes }
         updated_settings = ApplicationSetting.instance
         expect(updated_settings.read_only_message).to eq(new_attributes[:read_only_message])
         expect(updated_settings.announcement).to eq(new_attributes[:announcement])
       end

       it 'redirects to the edit page' do
         patch admin_application_settings_url, params: { application_setting: new_attributes }
         expect(response).to redirect_to(admin_application_settings_url)
       end
     end

     context 'with invalid parameters' do
       let(:user) { create(:user, :admin) }

       it "renders a successful response (i.e. to display the 'edit' template)" do
         patch admin_application_settings_url, params: { application_setting: invalid_attributes }
         expect(response).to redirect_to(admin_application_settings_url)
       end
     end
   end
 end
