# frozen_string_literal: true

class FileResourceSchema < BaseSchema
  def document
    DefaultSchema.new(resource: resource)
      .document
      .merge(extracted_text_document)
  end

  def reject
    [:file_data_tesim]
  end

  private

    def extracted_text_document
      return {} if resource.extracted_text.nil?

      {
        extracted_text_tei: resource.extracted_text
      }
    end
end
