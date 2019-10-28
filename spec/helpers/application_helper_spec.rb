# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  # Required by Devise when not using database_authenticatable
  describe '#new_session_path' do
    subject { helper.new_session_path }

    it { is_expected.to eq(new_user_session_path) }
  end
end
