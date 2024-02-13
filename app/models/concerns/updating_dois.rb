# frozen_string_literal: true

module UpdatingDois
  extend ActiveSupport::Concern

  included do
    attr_writer :update_doi

    after_commit :perform_update_doi, on: [:create, :update]
  end

  def update_doi?
    update_doi && resource_with_doi.doi.present?
  end

  private

    def update_doi
      @update_doi ||= false
    end

    def perform_update_doi
      return unless update_doi?

      DoiUpdatingJob.perform_later(resource_with_doi)
    end
end
