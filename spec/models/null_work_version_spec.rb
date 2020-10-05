# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NullWorkVersion do
  it { is_expected.to be_nil }
  it { is_expected.to be_empty }
  it { is_expected.to be_blank }
  it { is_expected.not_to be_present }

  its(:anything) { is_expected.to be_nil }
end
