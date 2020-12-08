# frozen_string_literal: true

class DisplayRightsComponent < ApplicationComponent
  attr_reader :id,
              :label

  def initialize(id:)
    @id = id
    @label = WorkVersion::Licenses.label(id)
  end

  def render?
    label.present?
  end
end
