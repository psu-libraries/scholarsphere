# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserRegistrationService do
  describe '.call' do
    context 'when no uid can be determined' do
      it 'raises an argument error' do
        expect {
          described_class.call
        }.to raise_error(ArgumentError, 'cannot register a user without a uid')
      end
    end

    context 'when the API sends the service only the uid' do
      context 'with a non-existent user' do
        let(:uid) { build(:user).access_id }
        let(:user) { User.find_by(access_id: uid) }

        it 'creates a new user with the provided uid' do
          expect {
            described_class.call(uid: uid)
          }.to change(User, :count).from(0).to(1)

          expect(user.given_name).to be_nil
          expect(user.surname).to be_nil
          expect(user.email).to eq("#{uid.downcase}@psu.edu")
          expect(user.groups).to contain_exactly(Group.public_agent, Group.authorized_agent)
        end
      end

      context 'with an existing user' do
        let!(:user) { create(:user) }

        it "does NOT update the user's fields" do
          registered_user = described_class.call(uid: user.access_id)
          expect(registered_user.attributes).to eq(user.attributes)
        end
      end
    end

    context 'when the UI sends the service the OmniAuth hash' do
      context 'with a non-existent user' do
        let(:auth) { build(:psu_oauth_response) }
        let(:user) { User.find_by(access_id: auth.uid) }

        it 'creates a new user and its groups with the given hash' do
          groups = Group.all - [Group.public_agent, Group.authorized_agent]
          expect(groups).to be_empty

          expect {
            described_class.call(auth: auth)
          }.to change(User, :count).from(0).to(1)

          groups = Group.all - [Group.public_agent, Group.authorized_agent]
          expect(groups.count).to eq(auth.info.groups.count)
          expect(user.given_name).to eq(auth.info.given_name)
          expect(user.surname).to eq(auth.info.surname)
          expect(user.email).to eq(auth.info.email.downcase)
          expect(user.groups.count).to eq(auth.info.groups.count + 2)
        end
      end

      context 'with an existing user' do
        let!(:user) { create(:user) }
        let(:auth) { build(:psu_oauth_response, uid: user.access_id) }

        it "updates the user's record" do
          registered_user = described_class.call(auth: auth)
          expect(registered_user.given_name).to eq(auth.info.given_name)
          expect(registered_user.surname).to eq(auth.info.surname)
          expect(registered_user.email).to eq(auth.info.email.downcase)
          expect(registered_user.access_id).to eq(user.access_id)
        end
      end
    end
  end
end
