# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkDepositPathways do
  describe '.details_form_for' do
    let(:wv) {
      instance_double(
        WorkVersion,
        deposit_pathway: pathway,
        attributes: { 'description' => 'test' }
      )
    }

    context 'when given an object with a scholarly_works deposit pathway' do
      let(:pathway) { :scholarly_works }

      it 'returns a new scholarly works details form initialized with the given object' do
        form = described_class.details_form_for(wv)
        expect(form).to be_a WorkDepositPathways::ScholarlyWorks::DetailsForm
        expect(form.description).to eq 'test'
      end
    end

    context 'when given an object with a general deposit pathway' do
      let(:pathway) { :general }

      it 'returns a new general details form initialized with the given object' do
        form = described_class.details_form_for(wv)
        expect(form).to be_a WorkDepositPathways::General::DetailsForm
        expect(form.description).to eq 'test'
      end
    end

    context 'when given an object with some other deposit pathway' do
      let(:pathway) { :other }

      it 'returns the given object' do
        form = described_class.details_form_for(wv)
        expect(form).to eq wv
      end
    end
  end
end
