# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::SearchBuilder do
  subject(:builder) { described_class.new(service) }

  let(:service) { Blacklight::SearchService.new(config: Blacklight::Configuration.new, user_params: {}, **context) }
  let(:context) { { current_user: user } }
  let(:user) { create(:user) }

  describe '.default_processor_chain' do
    its(:default_processor_chain) do
      is_expected.to include(
        :log_solr_parameters,
        :restrict_search_to_works_and_collections,
        :apply_gated_edit
      )
    end
  end

  describe '#processed_parameters' do
    let(:parameters) { builder.processed_parameters }

    it 'searches works and collections' do
      expect(parameters['fq']).to include('{!terms f=model_ssi}Work,Collection')
    end

    it "restricts search based on the users' permissions" do
      expect(parameters['fq']).to include(
        "({!terms f=edit_groups_ssim}#{Group::PUBLIC_AGENT_NAME},#{Group::AUTHORIZED_AGENT_NAME}) " \
        "OR edit_users_ssim:#{user.access_id} " \
        "OR {!terms f=depositor_id_isi}#{user.actor.id} " \
        "OR {!terms f=proxy_id_isi}#{user.actor.id}"
      )
    end

    context 'with an admin user' do
      let(:user) { create(:user, :admin) }

      it "does NOT restrict searches based on the user's permissions" do
        expect(parameters['fq']).not_to include(
          "{!terms f=depositor_id_isi}#{user.actor.id}"
        )
      end
    end
  end
end
