# frozen_string_literal: true

module EdtfDate
  def self.valid?(str)
    Date.edtf(str).present? || str.blank?
  end

  def self.humanize(str)
    Date.edtf(str)&.humanize || str.to_s
  rescue RuntimeError
    str.to_s
  end
end
