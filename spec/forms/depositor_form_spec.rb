# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DepositorForm, type: :model do
  subject(:form) { described_class.new(resource: resource, params: params) }

  let(:resource) { build(:work) }
  let(:user_attributes) { attributes_for(:user) }

  describe '#psu_id' do
    context 'without a value in the params' do
      let(:params) { {} }

      its(:psu_id) { is_expected.to eq(resource.depositor.psu_id) }
    end

    context 'with an id in the params' do
      let(:params) { { psu_id: user_attributes[:access_id] } }

      its(:psu_id) { is_expected.to eq(user_attributes[:access_id]) }
    end
  end

  describe '#save' do
    context 'when the actor exists in the system' do
      let(:actor) { create(:actor) }
      let(:params) { { psu_id: actor.psu_id } }

      it 'updates the resource with the existing actor' do
        form.save
        expect(resource.depositor).to eq(actor)
      end
    end

    context 'when the actor does NOT exist but is at Penn State' do
      let(:params) { { psu_id: user_attributes[:access_id] } }
      let(:actor) { build(:actor, psu_id: user_attributes[:access_id]) }

      before { allow(BuildNewActor).to receive(:call).with(psu_id: user_attributes[:access_id]).and_return(actor) }

      it 'returns a new actor' do
        form.save
        expect(resource.depositor).to eq(actor)
      end
    end

    context 'when the neither actor NOR Penn State user exists' do
      let(:params) { { psu_id: user_attributes[:access_id] } }

      before do
        allow(BuildNewActor).to receive(:call)
          .with(psu_id: user_attributes[:access_id])
          .and_raise(PsuIdentity::SearchService::NotFound)
      end

      it 'returns a new actor' do
        form.save
        expect(form.errors.full_messages).to include(
          "Access Account User #{user_attributes[:access_id]} could not be found"
        )
      end
    end
  end
end
