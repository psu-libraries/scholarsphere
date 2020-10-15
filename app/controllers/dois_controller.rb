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

    # @note We have some ridiculous hoops to jump through here.
    # 1. We can only send an actual, undecorated ActiveRecord through ActiveJob
    # 2. The ResourceDecorator and associated subclasses define a method called
    #    `resource_with_doi` because the WorkVersion cannot currently receive a
    #    doi, only the parent work can.
    # Therefore, we need to decorate the resource, ask it what the
    # resource-with-doi is, then un-decorate the returned object.
    def find_resource
      # Note the param is called :resource_id, but it's actually a uuid
      undecorated_resource = FindResource.call(params[:resource_id])
      decorated_resource = ResourceDecorator.decorate(undecorated_resource)
      resource_with_doi = decorated_resource.resource_with_doi

      # If resource_with_doi is decorated (`__getobj__`), undecorate before
      # returning
      if resource_with_doi.respond_to?(:__getobj__)
        resource_with_doi.__getobj__
      else
        resource_with_doi
      end
    end

    def doi_present_or_minting?(resource)
      resource.doi.present? || DoiMintingStatus.new(resource).present?
    end
end
