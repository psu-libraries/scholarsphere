# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OrcidValidator do
  subject(:model) { OrcidTestModel.new }

  before do
    stub_const('OrcidTestModel', Struct.new(:orcid_field) {
      include ActiveModel::Validations
      validates :orcid_field, orcid: true
    })
  end

  context 'with a valid ORCiD id' do
    before { model.orcid_field = FactoryBotHelpers.generate_orcid }

    it { is_expected.to be_valid }
  end

  context 'with a null value' do
    it { is_expected.to be_valid }
  end

  context 'with an invalid ORCiD id' do
    before { model.orcid_field = Faker::Number.leading_zero_number(digits: 16) }

    it 'is expected not to be valid' do
      expect(model).not_to be_valid
      expect(model.errors[:orcid_field]).to contain_exactly(
        I18n.t('errors.messages.invalid_orcid')
      )
    end
  end
end
