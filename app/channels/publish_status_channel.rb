class PublishStatusChannel < ApplicationCable::Channel
    def subscribed
      stream_for "publish_status"
    end
  end