# frozen_string_literal: true

class WorkDecorator < ResourceDecorator
  def decorated_versions
    versions.map { |version| WorkVersionDecorator.new(version) }
  end

  def decorated_representative_version
    WorkVersionDecorator.new(representative_version)
  end

  delegate :title,
           to: :representative_version,
           allow_nil: true
end
