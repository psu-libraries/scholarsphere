# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ManualReviewForm, type: :model do
  subject(:form) { described_class.new(resource: resource, params: params) }

  let(:resource) { build(:work) }

  describe 'initialization' do
    context 'with no params' do
      let(:params) { {} }

      its(:under_manual_review) { is_expected.to be_nil }
    end

    context 'with under_manual_review value' do
      let(:params) { { under_manual_review: true } }

      its(:under_manual_review) { is_expected.to eq(true) }
    end
  end

  describe '#save' do
    let(:params) { { under_manual_review: true } }

    it 'sets resource.under_manual_review to the form value and saves the resource' do
      form.save
      resource.reload
      expect(resource.under_manual_review).to eq(true)
    end
  end
end
