# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserDecorator do
  subject { described_class.new(user) }

  let(:user) { instance_double 'User' }

  it 'extends SimpleDelegator' do
    expect(described_class).to be < SimpleDelegator
  end

  describe '#display_name' do
    context 'when user is a guest' do
      before { allow(user).to receive(:guest?).and_return(true) }

      its(:display_name) { is_expected.to eq I18n.t!('navbar.guest_name') }
    end

    context 'when user is not a guest' do
      before do
        allow(user).to receive(:guest?).and_return(false)
        allow(user).to receive(:admin?).and_return(false)
        allow(user).to receive(:name).and_return('Pat Developer')
        allow(user).to receive(:access_id).and_return('pd123')
      end

      its(:display_name) { is_expected.to eq 'Pat Developer (pd123)' }
    end

    context 'when the user is an admin' do
      before do
        allow(user).to receive(:guest?).and_return(false)
        allow(user).to receive(:admin?).and_return(true)
      end

      its(:display_name) { is_expected.to eq I18n.t!('navbar.admin_name') }
    end
  end
end
