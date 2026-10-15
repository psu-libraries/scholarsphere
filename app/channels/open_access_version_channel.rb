# frozen_string_literal: true

class OpenAccessVersionChannel < ApplicationCable::Channel
  def subscribed
    work_version = WorkVersion.find_by(id: params[:id])
    return reject unless work_version

    stream_for work_version
  end
end
