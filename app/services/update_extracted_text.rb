# frozen_string_literal: true

# @abstract Updates the extracted text for a give FileResource.
class UpdateExtractedText
  def self.call(resource:, force: false)
    return if resource.extracted_text.present? && (force != true)

    MetadataListener::Job.perform_later(
      path: [resource.file_data['storage'], resource.file_data['id']].join('/'),
      endpoint: FileUploader.api_endpoint(resource),
      api_token: ExternalApp.metadata_listener.token,
      services: [:extracted_text]
    )
  end
end
