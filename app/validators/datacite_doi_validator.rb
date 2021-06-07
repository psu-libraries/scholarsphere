# frozen_string_literal: true

class DataciteDoiValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if Doi.valid_datacite_doi?(value)

    record.errors.add(attribute, (options[:message] || :invalid_doi))
  end
end
