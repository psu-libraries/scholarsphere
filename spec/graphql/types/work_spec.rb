# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Types::Work, type: :model do
  subject { described_class }

  its(:name) { is_expected.to eq('Types::Work') }
end
