# frozen_string_literal: true

class WorkDecorator < ResourceDecorator
  def versions
    super.map { |version| WorkVersionDecorator.new(version) }
  end

  def latest_published_version
    WorkVersionDecorator.new(super)
  end
end
