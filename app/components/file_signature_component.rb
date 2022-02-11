# frozen_string_literal: true

class FileSignatureComponent < ApplicationComponent
  attr_reader :type

  def initialize(file:, type:)
    @file = file
    @type = type
  end

  def render?
    signature.present?
  end

  def signature_display
    signature.truncate(10)
  end

  def tooltip
    signature
  end

  private

    def signature
      @file.signature(type: type)
    end
end
