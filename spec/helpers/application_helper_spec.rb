# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  # Required by Devise when not using database_authenticatable
  describe '#new_session_path' do
    subject { helper.new_session_path }

    it { is_expected.to eq(new_user_session_path) }
  end

  # Required to exist by default Blacklight. Does not exist because we're not
  # using database_authenticatable
  describe '#edit_user_registration_path' do
    subject { helper.edit_user_registration_path }

    it { is_expected.to eq '/' }
  end
end
