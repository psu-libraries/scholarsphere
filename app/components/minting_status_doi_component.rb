# frozen_string_literal: true

# This class wraps around DisplayDoiComponent, to add minting status to it if
# the doi is actively being minted. Once the doi is minted, it just calls
# DisplayDoiComponent

class MintingStatusDoiComponent < ApplicationComponent
  attr_reader :resource

  attr_writer :minting_status_source

  def initialize(resource:)
    @resource = resource
  end

  def render?
    display_doi_component.render? || resource_is_minting_doi?
  end

  def css_class
    {
      waiting: 'badge-light',
      minting: 'badge-light',
      error: 'badge-danger'
    }[status]
  end

  def resource_is_minting_doi?
    @resource_is_minting_doi ||= minting_status.present?
  end

  def display_doi_component
    @display_doi_component ||= DisplayDoiComponent.new(doi: resource.doi)
  end

  def display_content
    I18n.t("resources.doi.#{status}")
  end

  def status
    if resource_is_minting_doi?
      return :waiting if minting_status.waiting?
      return :minting if minting_status.minting?

      :error
    end
  end

  def minting_status
    @minting_status ||= minting_status_source.call(resource)
  end

  def minting_status_source
    @minting_status_source ||= DoiMintingStatus.public_method(:new)
  end
end
