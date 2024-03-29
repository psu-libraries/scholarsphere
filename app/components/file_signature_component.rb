# frozen_string_literal: true

class FileSignatureComponent < ApplicationComponent
  attr_reader :label, :value

  def initialize(file:)
    @file = file
    @signature = signature
  end

  def render?
    signature.present?
  end

  def signature_display
    @value[0, 7]
  end

  private

    def signature
      if sha256
        @label = 'sha256'
        @value = sha256
      elsif md5
        @label = 'md5'
        @value = md5
      end
    end

    def md5
      @file.md5
    end

    def sha256
      @file.sha256
    end
end
