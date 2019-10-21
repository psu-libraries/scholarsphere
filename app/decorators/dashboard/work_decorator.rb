# frozen_string_literal: true

module Dashboard
  class WorkDecorator < SimpleDelegator
    # @todo remove with_index once we explicitly store the version index
    def versions
      super.map.with_index { |version, index| WorkVersionDecorator.new(version, index) }
    end
  end
end
