# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Orcid, type: :model do
  subject { described_class.new(id) }

  context 'with a properly formatted string' do
    let(:id) { FactoryBotHelpers.generate_orcid }

    it { is_expected.to be_valid }
    its(:to_s) { is_expected.to eq("https://orcid.org/#{id}") }
    its(:uri) { is_expected.to eq(URI("https://orcid.org/#{id}")) }
  end

  context 'when verifying an existing id' do
    let(:id) { described_class.new(FactoryBotHelpers.generate_orcid).to_s }

    it { is_expected.to be_valid }
  end

  context 'with unformatted numbers' do
    let(:id) { Faker::Number.leading_zero_number(digits: 16) }

    it { is_expected.not_to be_valid }
  end

  context 'with junk' do
    let(:id) { Faker::Alphanumeric.alphanumeric(number: 10) }

    it { is_expected.not_to be_valid }
  end
end
