# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDocument, type: :model do
  subject { described_class.new(document) }

  describe '#deposited_at' do
    context 'when the value exists' do
      let(:document) { { deposited_at_dtsi: '2020-11-10T02:05:05Z' } }

      its(:deposited_at) { is_expected.to be_a(Time) }
    end

    context 'when the value is nil' do
      let(:document) { {} }

      its(:deposited_at) { is_expected.to be_nil }
    end
  end
end
