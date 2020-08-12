# frozen_string_literal: true

class WorkDecorator < ResourceDecorator
  def decorated_versions
    versions.map { |version| WorkVersionDecorator.new(version) }
  end

  def decorated_latest_published_version
    WorkVersionDecorator.new(latest_published_version)
  end
end
