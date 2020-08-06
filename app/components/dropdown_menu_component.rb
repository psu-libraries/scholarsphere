# frozen_string_literal: true

class DropdownMenuComponent < ApplicationComponent
  attr_reader :id,
              :label

  def initialize(id:, label:)
    @id = id
    @label = label
  end
end
