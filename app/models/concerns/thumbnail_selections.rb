# frozen_string_literal: true

module ThumbnailSelections
  extend ActiveSupport::Concern

  DEFAULT_ICON = 'default_icon'
  UPLOADED_IMAGE = 'uploaded_image'
  AUTO_GENERATED = 'auto_generated'

  included do
    validates :thumbnail_selection,
              inclusion: [DEFAULT_ICON,
                          UPLOADED_IMAGE,
                          AUTO_GENERATED],
              presence: true
  end

  def auto_generated_thumbnail?
    thumbnail_selection == AUTO_GENERATED
  end

  def default_thumbnail?
    thumbnail_selection == DEFAULT_ICON
  end
end
