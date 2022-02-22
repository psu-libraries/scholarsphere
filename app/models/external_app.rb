# frozen_string_literal: true

class ExternalApp < ApplicationRecord
  has_many :api_tokens,
           dependent: :destroy,
           foreign_key: 'application_id',
           inverse_of: 'application'

  has_many :work_versions,
           dependent: :nullify

  validates :name,
            presence: true,
            uniqueness: true

  validates :contact_email,
            presence: true

  alias_attribute :access_id, :name

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

  def guest?
    false
  end

  # @note For all intensive purposes, external applications have admin rights: they aren't limited in what they can do.
  # This may change later, giving them access controls or other mechanisms, which is a more involved process.
  def admin?
    true
  end

  # @note External applications cannot have associated actors. They are neither depositors nor proxies. However,
  # they due behave like users, so they need a method that respond accordingly.
  def actor
    @actor ||= NullActor.new
  end
end
