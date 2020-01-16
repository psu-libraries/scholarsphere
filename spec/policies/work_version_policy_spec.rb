# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersionPolicy, type: :policy do
  let(:user) { instance_double 'User' }
  let(:work) { instance_double 'Work' }
  let(:work_version) { instance_double 'WorkVersion', work: work }

  describe '#show?' do
    it 'delegates to Work#read_access?' do
      allow(work).to receive(:read_access?)
        .with(user).and_return(:whatever_read_access_returns)

      expect(described_class.new(user, work_version).show?).to eq :whatever_read_access_returns
    end
  end
end
