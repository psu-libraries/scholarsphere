# frozen_string_literal: true

class PublishStatusChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'publish_status_channel'
  end
end
