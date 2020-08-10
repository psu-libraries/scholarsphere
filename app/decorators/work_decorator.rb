# frozen_string_literal: true

class WorkDecorator < ResourceDecorator
  def versions
    super.map { |version| WorkVersionDecorator.new(version) }
  end
end
