# frozen_string_literal: true

class FlashMessageComponent < ApplicationComponent
  attr_reader :flash

  def initialize(flash:)
    @flash = flash
  end

  def messages
    read_only_message + flash_messages
  end

  def render?
    messages.present?
  end

  class Message
    attr_reader :type, :content

    def initialize(type, content)
      @type = type
      @content = content
    end

    def html_classes
      "alert #{alert_class.fetch(type, default_class)}"
    end

    def alert_class
      HashWithIndifferentAccess.new({
                                      success: 'alert-success',
                                      notice: 'alert-info',
                                      alert: 'alert-warning',
                                      error: 'alert-danger'
                                    })
    end

    def default_class
      "alert-#{type}"
    end
  end

  private

    def flash_messages
      flash.map do |message|
        Message.new(*message)
      end
    end

    def read_only_message
      return [] unless Rails.application.read_only?

      [Message.new('alert', I18n.t('read_only'))]
    end
end
