# frozen_string_literal: true

module EdtfDate
  def self.valid?(str)
    regular_date = begin
                     Date.parse(str)
                   rescue ArgumentError, TypeError
                     nil
                   end

    edtf_date = Date.edtf(str)

    (regular_date || edtf_date).present?
  end
end
