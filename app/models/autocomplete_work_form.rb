# frozen_string_literal: true

class AutocompleteWorkForm
  include ActiveModel::Model
  attr_accessor :doi

  validate :doi, :valid_doi?

  def valid_doi?
    Doi.new(doi).valid?
  end
end