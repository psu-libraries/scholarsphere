# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NullObjectPattern do
  subject { NullTest.new }

  before(:all) do
    class NullTest
      include NullObjectPattern
    end
  end

  after(:all) do
    Object.send(:remove_const, 'NullTest') if Object.const_defined?(:NullTest)
  end

  it { is_expected.to be_nil }
  it { is_expected.to be_empty }
  it { is_expected.to be_blank }
  it { is_expected.not_to be_present }

  its(:anything) { is_expected.to be_nil }
end
