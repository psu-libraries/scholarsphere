# frozen_string_literal: true

class FacetSchema < BaseSchema
  def document
    {
      subject_sim: resource.try(:subject),
      keyword_sim: resource.try(:keyword)
    }.select { |_k, v| v.present? }
  end
end
