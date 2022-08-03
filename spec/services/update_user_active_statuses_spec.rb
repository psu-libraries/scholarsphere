# frozen_string_literal: true

require 'rails_helper'

describe UpdateUserActiveStatuses do
  let!(:user) { create(:user) }

  context 'when user is active faculty' do
    let(:response) do
      object_double(PsuIdentity::SearchService::Person.new,
                    affiliation: ['FACULTY', 'MEMBER'])
    end

    before do
      user.active = false
      user.save!
      allow_any_instance_of(PsuIdentity::SearchService::Client).to receive(:userid).and_return response
    end

    it 'updates user active status to true' do
      described_class.call
      user.reload
      expect(user.active).to be true
    end
  end

  context 'when user is just a MEMBER' do
    let(:response) do
      object_double(PsuIdentity::SearchService::Person.new,
                    affiliation: ['MEMBER'])
    end

    before do
      allow_any_instance_of(PsuIdentity::SearchService::Client).to receive(:userid).and_return response
    end

    it 'updates user active status to false' do
      described_class.call
      user.reload
      expect(user.active).to be false
    end
  end

  context 'when no user is found' do
    before do
      allow_any_instance_of(PsuIdentity::SearchService::Client)
        .to receive(:userid)
        .and_raise PsuIdentity::SearchService::NotFound
    end

    it 'updates user active status to false' do
      described_class.call
      user.reload
      expect(user.active).to be false
    end
  end

  context 'when timeout occurs' do
    before do
      allow_any_instance_of(PsuIdentity::SearchService::Client).to receive(:userid).and_raise Net::ReadTimeout
    end

    it 'does not change user active status' do
      expect { described_class.call }.not_to change(user, :active)
    end
  end
end
