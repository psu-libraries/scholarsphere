# frozen_string_literal: true

class CitationComponent < ApplicationComponent
  attr_reader :citation

  def initialize(citation)
    @citation = citation
  end

  def render?
    citation.present?
  end
end
