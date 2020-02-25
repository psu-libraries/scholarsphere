# frozen_string_literal: true

class LegacyUrlsController < ApplicationController
  # Handles legacy urls from Scholarsphere v3
  def v3
    uuid = LegacyIdentifier.find_uuid(version: 3, old_id: params[:id])
    redirect_to resource_path(uuid)
  end
end
