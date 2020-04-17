# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::WorkPolicy, type: :policy do
  subject(:policy) { described_class }

  let(:user) { create :user }
  let(:user_actor) { user.actor }

  let(:other_user) { build_stubbed :user }

  permissions '.scope' do
    let(:scoped_works) { described_class::Scope.new(user, Work).resolve }

    let!(:deposited_work) { create :work, depositor: user_actor }
    let!(:proxied_work) { create :work, proxy_depositor: user_actor }

    before do
      create :work # Another user's work
    end

    it 'only finds my works' do
      expect(scoped_works).to match_array([deposited_work, proxied_work])
    end
  end

  permissions :create_version? do
    let(:work) { create :work, depositor: user_actor, has_draft: true }

    context 'when a draft exists' do
      it { is_expected.not_to permit(user, work) }
      it { is_expected.not_to permit(other_user, work) }
    end

    context 'when no draft exists' do
      let(:work) { create :work, depositor: user_actor, has_draft: false }

      it { is_expected.to permit(user, work) }
      it { is_expected.not_to permit(other_user, work) }
    end
  end
end
