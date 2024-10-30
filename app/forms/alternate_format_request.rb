# frozen_string_literal: true

class AlternateFormatRequest
  include ActiveModel::Model

  attr_accessor :url, :email, :message, :name, :title

  validates :url, :email, :message, :name, :title, presence: true

  def initialize(file_version = nil, current_user = nil)
    @email = current_user&.email
    @name = current_user&.display_name
    @title = file_version&.title
    @url = file_version&.file_version_download_url
  end
end
