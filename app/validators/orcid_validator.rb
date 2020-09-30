# frozen_string_literal: true

# @abstract A wrapper to ActiveRecordize Orcid.valid?
class OrcidValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?

    record.errors.add(attribute, (options[:message] || :invalid_orcid)) unless Orcid.valid?(value)
  end
end
