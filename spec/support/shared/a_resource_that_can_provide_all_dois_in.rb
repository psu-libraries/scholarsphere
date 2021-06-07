# frozen_string_literal: true

RSpec.shared_examples 'a resource that can provide all DOIs in' do |fields_with_dois|
  its(:fields_with_dois) { is_expected.to match_array fields_with_dois }
  its(:all_dois) { is_expected.to be_a Array }

  describe 'DOI validations' do
    it { is_expected.not_to allow_value(FactoryBotHelpers.valid_doi).for(:doi) }
    it { is_expected.not_to allow_value(FactoryBotHelpers.invalid_doi).for(:doi) }
    it { is_expected.not_to allow_value(FactoryBotHelpers.unmanaged_doi).for(:doi) }
    it { is_expected.to allow_value(FactoryBotHelpers.datacite_doi).for(:doi) }
  end
end
