# frozen_string_literal: true

class BaseSchema
  attr_reader :resource

  def initialize(resource:)
    @resource = resource
  end

  def document
    raise ArgumentError, 'Inheriting class must implement #document'
  end
end
