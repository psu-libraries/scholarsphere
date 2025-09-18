# frozen_string_literal: true

# @abstract A wrapper to ActiveRecordize EdtfDate.valid?
class EdtfDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if EdtfDate.valid?(value)

    record.errors.add(attribute, options[:message] || :invalid_edtf)
  end
end
