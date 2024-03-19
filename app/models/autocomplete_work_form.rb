# frozen_string_literal: true

class AutocompleteWorkForm
  include ActiveModel::Model
  attr_accessor :doi

  validate :doi, :valid_doi?

  def valid_doi?
    errors.add(:autocomplete, 'failed: not a valid DOI') unless Doi.new(doi).valid?
  end
end
