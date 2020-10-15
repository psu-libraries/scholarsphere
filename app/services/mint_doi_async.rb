# frozen_string_literal: true

class MintDoiAsync
  def self.call(resource)
    status = DoiMintingStatus.new(resource)

    status.waiting!
    DoiMintingJob.perform_later(resource)
  end
end
