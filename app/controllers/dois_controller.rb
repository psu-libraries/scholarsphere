# frozen_string_literal: true

class DoisController < ApplicationController
  class DoiIsMintingError < RuntimeError; end

  def create
    resource = find_resource

    authorize(resource, :edit?)
    raise DoiIsMintingError if doi_present_or_minting?(resource)

    MintDoiAsync.call(resource)
  rescue DoiIsMintingError
    # I don't think we need to do anything special here, just skip over the call
    # to MintDoiAsync and redirect back where we came from?
  ensure
    redirect_to resource_path(params[:resource_id])
  end

  private

    # At the moment, WorkVersions cannot get their own DOIs, their parent work
    # does. This rule is encapsulated by the #resource_with_doi interface on
    # Collections, Works, and WorkVersions
    def find_resource
      # Note the param is called :resource_id, but it's actually a uuid
      requested_resource = FindResource.call(params[:resource_id])
      requested_resource.resource_with_doi
    end

    def doi_present_or_minting?(resource)
      resource.doi.present? || DoiMintingStatus.new(resource).present?
    end
end
