# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DataciteDoiValidator do
  subject(:model) { DataciteDoiTestModel.new }

  before do
    stub_const('DataciteDoiTestModel', Struct.new(:doi_field) {
      include ActiveModel::Validations
      validates :doi_field, datacite_doi: true
    })
  end

  context 'with a valid Datacite DOI' do
    before { model.doi_field = FactoryBotHelpers.datacite_doi }

    it { is_expected.to be_valid }
  end

  context 'with a invalid Datacite DOI' do
    # A valid DOI does not mean a valid Datacite DOI
    before { model.doi_field = FactoryBotHelpers.valid_doi }

    it 'is expected not to be valid' do
      expect(model).not_to be_valid
      expect(model.errors[:doi_field]).to contain_exactly(
        I18n.t('errors.messages.invalid_doi')
      )
    end
  end
end
