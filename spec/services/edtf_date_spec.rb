# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EdtfDate do
  describe '::valid?' do
    {
      # Valid EDTF dates
      '1999-uu-uu' => true,
      '1984?-01~' => true,

      # Blank values
      nil => true,
      '' => true,

      # Valid Ruby dates, but invalid EDTF dates
      'January 21, 2019' => false,
      'January' => false,
      '17th Century' => false,

      # Invalid values
      'asdf' => false,
      'January 41, 2019' => false

    }.each do |date, expected_value|
      it "validates #{date.inspect} as #{expected_value}" do
        expect(described_class.valid?(date)).to be expected_value
      end
    end
  end

  describe '::humanize' do
    { # GIVEN       => EXPECTED
      '2019-05-01' => 'May 1, 2019',
      '1981~' => 'circa 1981',
      '1965/1975' => '1965 to 1975',

      # Bogus data
      'not a date' => 'not a date',
      '' => '',
      nil => '',
      1 => '1'
    }.each do |edtf_date, expected_output|
      it "formats #{edtf_date.inspect} as #{expected_output.inspect}" do
        expect(described_class.humanize(edtf_date)).to eq expected_output
      end
    end
  end
end
