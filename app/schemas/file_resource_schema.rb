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
      return {} if extracted_text.nil?

      {
        extracted_text_tei: text_content
      }
    end

    def extracted_text
      @extracted_text ||= resource.extracted_text
    end

    def text_content
      extracted_text.rewind
      extracted_text.read
    end
end
