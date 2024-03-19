# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutocompleteWorkForm, type: :model do
  subject(:form) { described_class.new(doi: doi) }

  describe '#valid?' do
    context 'when doi is valid' do
      let(:doi) { 'https://doi.org/10.1515/pol-2020-2011' }

      it 'returns true' do
        expect(form.valid?).to eq true
      end
    end

    context 'when doi is not valid' do
      let(:doi) { 'https://doi.org/junkdoi' }

      it 'returns false' do
        expect(form.valid?).to eq false
      end
    end

    context 'when doi is blank' do
      let(:doi) { '' }

      it 'returns false' do
        expect(form.valid?).to eq false
      end
    end
  end
end
