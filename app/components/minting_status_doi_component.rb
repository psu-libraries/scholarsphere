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
    display_doi_component.render? || resource_is_minting_doi? || invalid?
  end

  def css_class
    {
      waiting: 'badge badge-light',
      minting: 'badge badge-light',
      error: 'text-danger',
      blocked: 'text-danger'
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
    return :blocked if invalid?

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

  def invalid?
    !validation
  end

  private

    def validation
      @validation ||= if resource.is_a?(Work)
                        resource.latest_version.validate
                      else
                        resource.validate
                      end
    end
end
