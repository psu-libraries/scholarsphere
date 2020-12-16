# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::MemberWorksSearchBuilder do
  subject(:builder) { described_class.new(service) }

  let(:service) { Blacklight::SearchService.new(config: Blacklight::Configuration.new, user_params: {}, **context) }
  let(:context) { { current_user: user } }
  let(:user) { create(:user) }

  describe '.default_processor_chain' do
    its(:default_processor_chain) do
      is_expected.to include(
        :log_solr_parameters,
        :search_only_latest_work_versions,
        :apply_gated_edit,
        :build_member_works_query
      )
    end
  end

  describe '#processed_parameters' do
    let(:parameters) { builder.processed_parameters }

    it 'searches only published work versions' do
      expect(parameters['fq']).to include(
        '({!terms f=aasm_state_tesim}published)'
      )
    end
  end
end
