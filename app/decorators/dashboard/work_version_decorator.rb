# frozen_string_literal: true

class Dashboard::WorkVersionDecorator < ResourceDecorator
  def display_name
    "Version #{version_name.presence || version_number}"
  end

  # @todo store dates for specific workflow actions such as published and withdrawn
  def display_date
    if draft?
      "Updated #{updated_at.to_date.to_s(:long)}"
    else
      "Published #{display_published_date}"
    end
  end
end
