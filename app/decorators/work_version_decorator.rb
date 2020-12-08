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

  def display_rights
    DisplayRightsComponent.new(id: rights)
  end

  private

    def version_name_or_number
      version_name.presence || version_number
    end
end
