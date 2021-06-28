# frozen_string_literal: true

class FileResourceSchema < BaseSchema
  def document
    DefaultSchema.new(resource: resource)
      .document
      .merge(extracted_text_document)
      .merge(metadata_document)
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

    def metadata_document
      {
        mime_type_ssi: resource.file.mime_type,
        size_isi: resource.file.size,
        original_filename_ssi: resource.file.original_filename
      }
    end
end
