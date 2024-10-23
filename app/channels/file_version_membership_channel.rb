class FileVersionMembershipChannel < ApplicationCable::Channel
  def subscribed
    membership = FileVersionMembership.find(params[:id])
    stream_for membership
  end
end
