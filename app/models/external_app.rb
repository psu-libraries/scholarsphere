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

  # @note This is used in work histories, which (typically) display the names of users who have made changes to a work.
  # If this pattern goes beyond here, it would be a good idea to refactor it into a decorator.
  def access_id
    name
  end

  # @note ExternalApp and User need to behave in similar ways. This could be extracted into a decorator. See above note
  # for #access_id.
  def guest?
    false
  end
end
