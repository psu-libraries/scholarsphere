# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::WorkPolicy, type: :policy do
  subject(:policy) { described_class }

  let(:depositor) { work.depositor }
  let(:other_user) { instance_double('User', 'another user') }

  permissions :create_version? do
    let(:work) { create :work, has_draft: true }
    context 'when a draft exists' do
      it { is_expected.not_to permit(depositor, work) }
      it { is_expected.not_to permit(other_user, work) }
    end

    context 'when no draft exists' do
      let(:work) { create :work, has_draft: false }

      it { is_expected.to permit(depositor, work) }
      it { is_expected.not_to permit(other_user, work) }
    end
  end
end
