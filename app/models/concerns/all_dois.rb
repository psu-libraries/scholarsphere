# frozen_string_literal: true

module AllDois
  extend ActiveSupport::Concern

  included do
    # Defines a class-level macro where you specify which fields in your model
    # might contain DOIs
    #
    # @example
    #     class MyExample
    #       include AllDois
    #       fields_with_dois :doi, :other_identifiers, :publisher_url
    #     end
    def self.fields_with_dois(*args)
      symbolized_args = args.map(&:to_sym)
      define_method(:fields_with_dois) { symbolized_args }
    end

    # Validates the Datacite DOI field to ensure it's in the correct format for the API
    validates :doi,
              datacite_doi: true,
              unless: -> { doi.blank? }
  end

  # Returns an arary of all valid dois found within the methods specified by the
  # macro call to `fields_with_dois`
  #
  # For example, if your class specified
  #     fields_with_dois :doi, :identifiers
  #
  # Then this method would call `#doi` and `#identifiers` and search for valid
  # dois within their returned values. Methods that return arrays are
  # automatically flattened. All valid dois found are returned as formatted
  # strings in an array.
  def all_dois
    # WorkVersions should only be included here if they are the
    # latest_published_version? and their associated Work does not have a DOI
    return [] if forbidden_work_version?

    fields_with_dois
      .flat_map { |field_name| send(field_name) }
      .lazy
      .map { |value| Doi.new(value) }
      .filter(&:valid?)
      .map(&:to_s)
      .uniq
      .to_a
  end

  private

    def forbidden_work_version?
      return false unless self.class == WorkVersion

      !self.latest_published_version? || (self.latest_published_version? &&
              self.work.fields_with_dois.collect { |field| self.work.send(field).present? }.include?(true))
    end
end
