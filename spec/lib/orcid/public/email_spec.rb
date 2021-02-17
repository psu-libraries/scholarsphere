# frozen_string_literal: true

require 'spec_helper'
require 'rspec/its'
require 'support/vcr'
require 'orcid'

RSpec.describe Orcid::Public::Email, :vcr do
  subject(:email) { described_class.new(id: id) }

  let(:id) { '0000-0001-8485-6532' }

  describe '#addresses' do
    context 'when calling the API' do
      it 'returns all public addresses' do
        expect(email.addresses[0].to_s).to eq('agw13@psu.edu')
        expect(email.addresses[0].visibility).to eq('PUBLIC')
        expect(email.addresses[0]).to be_verified
        expect(email.addresses[0]).not_to be_primary
        expect(email.addresses[1].to_s).to eq('awead@psu.edu')
        expect(email.addresses[1].visibility).to eq('PUBLIC')
        expect(email.addresses[1]).to be_verified
        expect(email.addresses[1]).not_to be_primary
      end
    end

    context 'when providing data' do
      subject(:email) { described_class.new(id: id, data: data) }

      let(:data) do
        { 'email' => [] }
      end

      it 'returns all the addresses' do
        expect(email.addresses).to be_empty
      end
    end
  end

  describe '#primary' do
    context 'when a primary email is present' do
      its(:primary) { is_expected.to eq('awead@psu.edu') }
    end

    context 'when a primary email is NOT present' do
      its(:primary) { is_expected.to be_nil }
    end
  end

  describe '#default' do
    context 'when a primary email is present' do
      its(:default) { is_expected.to eq('awead@psu.edu') }
    end

    context 'when a primary email is NOT present' do
      its(:default) { is_expected.to eq('agw13@psu.edu') }
    end
  end
end
