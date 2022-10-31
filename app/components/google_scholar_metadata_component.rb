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
    creators.map(&:display_name)
  end

  def citation_publication_date
    return deposited_at.year unless EdtfDate.valid?(published_date)

    Date.edtf(published_date).try(:year) || deposited_at.year
  end

  def citation_pdf_id
    file_version_memberships
      .includes(:file_resource)
      .select { |f| f.mime_type == 'application/pdf' }
      .min
      &.id
  end

  private

    def file_version_memberships
      return FileVersionMembership.none unless policy.download?

      resource.file_version_memberships
    end
end
