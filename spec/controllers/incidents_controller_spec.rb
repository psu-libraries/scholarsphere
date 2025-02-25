# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IncidentsController do
  describe '#new' do
    before { get :new }

    its(:response) { is_expected.to be_successful }
  end

  describe '#create' do
    let(:params) do
      {
        category: incident.category,
        name: incident.name,
        email: incident.email,
        subject: incident.subject,
        message: incident.message
      }
    end

    context 'with valid input' do
      let(:incident) { build(:incident) }

      it 'reports the incident' do
        expect {
          post :create, params: { incident: params }
        }.to change(ActionMailer::Base.deliveries, :count).by(1)
      end

      it 'redirects to the home page' do
        post :create, params: { incident: params }
        expect(response).to redirect_to(root_path)
      end
    end

    context 'with valid input from a Penn State user' do
      let(:incident) { build(:incident, :from_penn_state) }

      it 'reports the incident with a confirmation email' do
        expect {
          post :create, params: { incident: params }
        }.to change(ActionMailer::Base.deliveries, :count).by(2)
      end
    end

    context 'with invalid input' do
      let(:incident) { build(:incident, message: nil) }

      it 'does NOT send the email' do
        expect {
          post :create, params: { incident: params }
        }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end
  end
end
