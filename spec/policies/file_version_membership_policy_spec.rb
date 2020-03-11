# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileVersionMembershipPolicy, type: :policy do
  let(:user) { instance_double 'User' }
  let(:file_version_membership) { instance_double 'FileVersionMembership', work_version: work_version }
  let(:work_version) { instance_double 'WorkVersion' }
  let(:mock_policy) { instance_spy 'WorkVersionPolicy' }

  describe 'download?' do
    before { allow(Pundit).to receive(:policy).with(user, work_version).and_return(mock_policy) }

    it 'delegates to WorkVersionPolicy#download?' do
      described_class.new(user, file_version_membership).download?
      expect(mock_policy).to have_received(:download?)
    end
  end
end
