# frozen_string_literal: true

class ExternalApp < ApplicationRecord
  has_many :api_tokens,
           dependent: :destroy,
           foreign_key: 'application_id',
           inverse_of: 'application'

  validates :name,
            presence: true,
            uniqueness: true

  validates :contact_email,
            presence: true

  class MetadataListener
    NAME = 'Metadata Listener'

    def self.build
      ExternalApp.find_or_create_by(name: NAME) do |app|
        app.api_tokens.build
        app.contact_email = Rails.configuration.no_reply_email
      end
    end
  end

  def self.metadata_listener
    MetadataListener.build
  end

  def token
    api_tokens.first.token
  end
end
