# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchBuilder do
  subject(:builder) { described_class.new(service) }

  let(:service) { Blacklight::SearchService.new(config: Blacklight::Configuration.new, user_params: {}, **context) }
  let(:context) { { current_user: user } }
  let(:user) { User.guest }

  describe '.default_processor_chain' do
    its(:default_processor_chain) do
      is_expected.to include(
        :restrict_search_to_works_and_collections,
        :apply_gated_discovery,
        :limit_to_public_resources,
        :log_solr_parameters
      )
    end
  end

  describe '#processed_parameters' do
    let(:parameters) { builder.processed_parameters }

    context 'with a guest user' do
      it 'restricts searches to public works' do
        expect(parameters['fq']).to include(
          "({!terms f=discover_groups_ssim}#{Group::PUBLIC_AGENT_NAME})",
          '{!terms f=model_ssi}Work,Collection'
        )
      end
    end

    context 'with a registered user' do
      let(:user) { build(:user) }

      it 'restricts searches to public and registered works, as well as user-discoverable works' do
        expect(parameters['fq']).to include(
          "({!terms f=discover_groups_ssim}#{Group::PUBLIC_AGENT_NAME},#{Group::AUTHORIZED_AGENT_NAME}) " \
            "OR discover_users_ssim:#{user.access_id}",
          '{!terms f=model_ssi}Work,Collection'
        )
      end
    end

    context 'with an admin user' do
      let(:user) { build(:user, :admin) }

      it 'shows all Works' do
        expect(parameters['fq']).to contain_exactly('{!terms f=model_ssi}Work,Collection')
      end
    end

    context 'with an embargoed work' do
      it 'excludes works whose embargo date is in the future' do
        expect(parameters['fq']).to include(
          '-embargoed_until_dtsi:[NOW TO *]'
        )
      end
    end
  end
end
