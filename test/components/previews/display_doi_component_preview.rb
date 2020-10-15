# frozen_string_literal: true

class DisplayDoiComponentPreview < ViewComponent::Preview
  def default
    resource_without_doi = FactoryBot.build_stubbed(:work, doi: nil)

    mintable = MintableDoiComponent.new(resource: resource_without_doi)
    mintable.minting_policy_source = ->(_resource) { true }

    waiting = MintingStatusDoiComponent.new(resource: resource_without_doi)
    waiting.minting_status_source = ->(_resource) {
      OpenStruct.new(present?: true, waiting?: true, minting?: false, error?: false)
    }

    minting = MintingStatusDoiComponent.new(resource: resource_without_doi)
    minting.minting_status_source = ->(_resource) {
      OpenStruct.new(present?: true, waiting?: false, minting?: true, error?: false)
    }

    error = MintingStatusDoiComponent.new(resource: resource_without_doi)
    error.minting_status_source = ->(_resource) {
      OpenStruct.new(present?: true, waiting?: false, minting?: false, error?: true)
    }

    valid = MintingStatusDoiComponent.new(resource:
      FactoryBot.build_stubbed(:work, doi: FactoryBotHelpers.valid_doi))

    invalid = MintingStatusDoiComponent.new(resource:
      FactoryBot.build_stubbed(:work, doi: 'abc123badbad'))

    unmanaged = MintingStatusDoiComponent.new(resource:
      FactoryBot.build_stubbed(:work, doi: FactoryBotHelpers.unmanaged_doi))

    render_with_template(locals: {
                           mintable: mintable,
                           waiting: waiting,
                           minting: minting,
                           error: error,
                           valid: valid,
                           invalid: invalid,
                           unmanaged: unmanaged
                         })
  end
end
