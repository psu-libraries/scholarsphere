# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OrcidId do
  let(:id) { FactoryBotHelpers.generate_orcid }
  let(:formatted_id) { id.gsub(/(\d{4})(?!$)/, '\1-') }
  let(:uri) { URI("https://orcid.org/#{formatted_id}") }

  context 'with a string of 16 numbers' do
    subject { described_class.new(id) }

    it { is_expected.to be_valid }
    its(:to_s) { is_expected.to eq(id) }               # returns 1234123412341234
    its(:to_human) { is_expected.to eq(formatted_id) } # returns 1234-1234-1234-1234
    its(:uri) { is_expected.to eq(uri) }               # returns https://orcid.org/1234-1234-1234-1234
  end

  context 'when the check digit is an X' do
    subject { described_class.new(id) }

    let(:id) { Faker::Number.leading_zero_number(digits: 15) + 'X' }

    it { is_expected.to be_valid }
    its(:to_s) { is_expected.to eq(id) }               # returns 123412341234123X
    its(:to_human) { is_expected.to eq(formatted_id) } # returns 1234-1234-1234-123X
    its(:uri) { is_expected.to eq(uri) }               # returns https://orcid.org/1234-1234-1234-123X
  end

  context 'with a formatted string such as 1234-1234-1234-1234' do
    subject { described_class.new(formatted_id) }

    it { is_expected.to be_valid }
    its(:to_s) { is_expected.to eq(id) }               # returns 1234123412341234
    its(:to_human) { is_expected.to eq(formatted_id) } # returns 1234-1234-1234-1234
    its(:uri) { is_expected.to eq(uri) }               # returns https://orcid.org/1234-1234-1234-1234
  end

  context 'with a uri such as https://orcid.org/1234-1234-1234-1234' do
    subject { described_class.new(uri.to_s) }

    it { is_expected.to be_valid }
    its(:to_s) { is_expected.to eq(id) }               # returns 1234123412341234
    its(:to_human) { is_expected.to eq(formatted_id) } # returns 1234-1234-1234-1234
    its(:uri) { is_expected.to eq(uri) }               # returns https://orcid.org/1234-1234-1234-1234
  end

  context 'with junk' do
    subject { described_class.new(Faker::Alphanumeric.alphanumeric(number: 10)) }

    it { is_expected.not_to be_valid }
  end

  context 'with string content' do
    subject { described_class.new(Faker::Lorem.sentence) }

    it { is_expected.not_to be_valid }
  end
end
