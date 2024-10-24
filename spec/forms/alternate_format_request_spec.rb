# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlternateFormatRequest, type: :model do
  subject(:form) { described_class.new }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:message) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:title) }
  end
end
