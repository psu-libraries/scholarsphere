# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ReportsController, type: :controller do
  describe '#user_for_paper_trail' do
    let(:user) { create(:user) }

    before { log_in user }

    its(:user_for_paper_trail) { is_expected.to eq(user.to_gid) }
  end
end
