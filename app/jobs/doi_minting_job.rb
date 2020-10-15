# frozen_string_literal: true

class DoiMintingJob < ApplicationJob
  queue_as :doi

  def perform(resource)
    status = DoiMintingStatus.new(resource)

    status.minting!
    DoiService.call(resource)
    status.delete!
  rescue DoiService::Error => e
    handle_error(e, status)
  rescue DataCite::Client::Error => e
    handle_error(e, status)
  rescue DataCite::Metadata::Error => e
    handle_error(e, status)
  end

  def handle_error(err, status)
    status.error!
    # @todo more error handling here?
    raise err
  end
end
