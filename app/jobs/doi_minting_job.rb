# frozen_string_literal: true

class DoiMintingJob < ApplicationJob
  queue_as :doi

  def perform(resource)
    status = DoiStatus.new(resource)

    status.minting!
    DoiService.call(resource)
    status.delete!
  rescue DoiService::Error => e
    status.error!
    # @todo more error handling here?
    raise e
  end
end
