# frozen_string_literal: true

class WorkVersionDecorator < ResourceDecorator
  def display_version_long
    "Version #{version_name_or_number}"
  end

  def display_version_short
    "V#{version_name_or_number}"
  end

  def decorated_work
    WorkDecorator.new(work)
  end

  # @todo store dates for specific workflow actions such as published and withdrawn
  def display_date
    if draft?
      "Updated #{updated_at.to_date.to_s(:long)}"
    else
      "Published #{display_published_date}"
    end
  end

  # @note at this time we only support DOIs on Works, not Versions
  def resource_with_doi
    work
  end

  private

    def version_name_or_number
      version_name.presence || version_number
    end
end
