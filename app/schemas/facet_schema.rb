# frozen_string_literal: true

class FacetSchema < BaseSchema
  def document
    {
      subject_sim: resource.try(:subject),
      keyword_sim: resource.try(:keyword)
    }.compact_blank
  end
end
