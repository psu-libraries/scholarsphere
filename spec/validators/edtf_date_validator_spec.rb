# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EdtfDateValidator do
  subject(:model) { EdtfTestModel.new }

  before do
    stub_const('EdtfTestModel', Struct.new(:date_field) {
      include ActiveModel::Validations
      validates :date_field, edtf_date: true
    })
  end

  context 'with a valid EDTF date' do
    before { model.date_field = '1999-uu-uu' }

    it { is_expected.to be_valid }
  end

  context 'with an invalid EDTF date' do
    before { model.date_field = 'Christmas, 1999' }

    it 'is expected not to be valid' do
      expect(model).not_to be_valid
      expect(model.errors[:date_field]).to contain_exactly(
        I18n.t!('errors.messages.invalid_edtf')
      )
    end
  end
end
