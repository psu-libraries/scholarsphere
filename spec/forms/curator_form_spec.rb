# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CuratorForm, type: :model do
  subject(:form) { described_class.new(resource: resource, params: params) }

  let(:resource) { build(:work) }
  let(:user_attributes) { attributes_for(:user) }

  describe '#access_id' do
    context 'without a value in the params or a current curator' do
      let(:params) { {} }

      its(:access_id) { is_expected.to be_nil }
    end

    context 'with a current curator but without a value in the params' do
      let(:params) { {} }
      let(:resource) { build(:work) }
      let(:user) { create(:user) }
      let(:curatorship) { create(:curatorship, work: resource, user: user) }

      before { resource.curatorships << curatorship }

      its(:access_id) { is_expected.to eq(user.access_id) }
    end

    context 'with an id in the params' do
      let(:params) { { access_id: user_attributes[:access_id] } }

      its(:access_id) { is_expected.to eq(user_attributes[:access_id]) }
    end
  end

  describe '#save' do
    context 'when the user exists in the system' do
      let(:user) { create(:user) }
      let(:params) { { access_id: user.access_id } }

      it 'updates the resource with the user' do
        form.save
        expect(resource.curators).to include(user)
      end
    end

    context 'when the Penn State user does not exist' do
      let(:bad_access_id) { 'jkl9876' }
      let(:params) { { access_id: bad_access_id } }

      it 'does not save and creates an error' do
        form.save
        expect(form.errors.full_messages).to include(
          "Access Account User #{bad_access_id} could not be found"
        )
        expect(resource.curators).not_to include(bad_access_id)
      end
    end
  end
end
