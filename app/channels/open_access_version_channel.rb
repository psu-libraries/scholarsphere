# frozen_string_literal: true

class OpenAccessVersionChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'open_access_version_channel'
  end
end
