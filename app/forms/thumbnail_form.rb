# frozen_string_literal: true

class ThumbnailForm
  include ActiveModel::Model

  attr_reader :resource

  def initialize(resource:, params:)
    @resource = resource
    super(params)
  end

  def auto_generate_thumbnail
    @auto_generate_thumbnail ||= resource.auto_generate_thumbnail
  end

  def auto_generate_thumbnail=(auto_generate_thumbnail)
    @auto_generate_thumbnail = auto_generate_thumbnail
  end

  def save
    resource.auto_generate_thumbnail = @auto_generate_thumbnail
    return false if errors.present?

    resource.save
  end
end
