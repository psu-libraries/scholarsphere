# frozen_string_literal: true

class GoogleScholarMetadataComponent < ApplicationComponent
  attr_reader :resource,
              :policy

  delegate :title,
           :creators,
           :deposited_at,
           :published_date,
           to: :resource

  # @param [ResourceDecorator] resource
  # @param [ApplicationPolicy] policy
  def initialize(resource:, policy:)
    @resource = resource
    @policy = policy
  end

  def render?
    resource.is_a?(WorkVersionDecorator)
  end

  def citation_authors
    creators.map(&:alias)
  end

  def citation_publication_date
    return deposited_at.year unless EdtfDate.valid?(published_date)

    Date.edtf(published_date).year
  end

  def file_resources
    return [] unless policy.download?

    resource.file_resources
  end
end
