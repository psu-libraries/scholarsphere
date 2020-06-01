# frozen_string_literal: true

module Dashboard
  class WorkDecorator < ResourceDecorator
    def versions
      super.map { |version| WorkVersionDecorator.new(version) }
    end
  end
end
