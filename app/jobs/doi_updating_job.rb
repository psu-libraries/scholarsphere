# frozen_string_literal: true

class DoiUpdatingJob < ApplicationJob
  queue_as :doi

  def perform(resource)
    DoiService.call(resource)
  end
end
