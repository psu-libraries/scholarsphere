# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NavbarComponent, type: :component do
  describe '#display_name' do
    subject { described_class.new(current_user: current_user) }

    let(:current_user) { create(:user) }

    its(:display_name) do
      is_expected.to eq(
        "#{current_user.actor.given_name} #{current_user.actor.surname} (#{current_user.access_id})"
      )
    end
  end

  describe 'rendering' do
    let(:result) { render_inline(described_class.new(current_user: current_user)) }

    context 'with a guest user' do
      let(:current_user) { User.guest }

      it 'displays the login button' do
        expect(result.css('a.btn').map(&:text)).to include('Login')
      end
    end

    context 'with a registered user' do
      let(:current_user) { create(:user) }

      it 'displays a dropdown menu for the user' do
        expect(result.css('a.dropdown-item').map(&:text)).to include(
          'Profile',
          'Works',
          'Collections',
          'Logout'
        )
      end
    end
  end
end
