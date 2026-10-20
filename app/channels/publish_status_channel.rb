# frozen_string_literal: true

class PublishStatusChannel < ApplicationCable::Channel
  def subscribed
    work_version = WorkVersion.find(params[:id])

    return reject unless Pundit.policy!(current_user, work_version).edit?

    stream_for work_version
  end
end
