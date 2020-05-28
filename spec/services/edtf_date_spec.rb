# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EdtfDate do
  describe '::valid?' do
    {
      # Valid EDTF dates
      '1999-uu-uu' => true,
      '1984?-01~' => true,

      # Valid Ruby dates
      'January 21, 2019' => true,

      # Invalid values
      'asdf' => false,
      nil => false,
      '' => false,
      'January 41, 2019' => false

    }.each do |date, expected_value|
      it "validates #{date.inspect} as #{expected_value}" do
        expect(described_class.valid?(date)).to be expected_value
      end
    end
  end
end
