# frozen_string_literal: true

class MintDoiAsync
  def self.call(resource)
    status = DoiStatus.new(resource)

    status.waiting!
    DoiMintingJob.perform_later(resource)
  end
end
