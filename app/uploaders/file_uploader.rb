# frozen_string_literal: true

require 'image_processing/mini_magick'

class FileUploader < Shrine
  plugin :backgrounding
  plugin :add_metadata
  plugin :derivatives

  def self.api_endpoint(record)
    File.join(
      "#{Rails.application.routes.default_url_options[:protocol]}://",
      ENV.fetch('API_URL_HOST', Rails.application.routes.default_url_options[:host]),
      Rails.application.routes.url_helpers.api_v1_file_path(record.id)
    ).to_s
  end

  Attacher.derivatives_storage do |name|
    if name == :thumbnail
      :thumbnails
    end
  end

  Attacher.derivatives :thumbnail do |original|
    magick = ImageProcessing::MiniMagick.source(original).loader(page: 0).convert('png')
    {
      thumbnail: magick.resize_to_fill!(200, 200)
    }
  end

  # @note This sets the default metadata when a file is uploaded. Virus information is nil until updated by our external
  # metadata-listener service.
  add_metadata do
    {
      virus: { status: nil, scanned_at: nil }
    }
  end

  # Add page count metadata for PDFs
  add_metadata :page_count do |io, context|
    mime_type = context.dig(:metadata, 'mime_type')
    next unless mime_type == FileResource::PDF_MIME_TYPE

    begin
      tempfile =
        if io.respond_to?(:download)
          io.download
        else
          io
        end

      PDF::Reader.new(tempfile.path).page_count
    ensure
      tempfile.close! if tempfile.respond_to?(:close!) && tempfile != io
    end
  end

  Attacher.promote_block do
    Shrine::PromotionJob.perform_later(
      record: record,
      name: name.to_s,
      file_data: file_data
    )

    # @note The metadata job is kicked off concurrently with promotion, using the same file in Shrine's cache store.
    # This is dependent on storage bucket policies keeping those cached files for a period of time after they've been
    # uploaded. Currently, this is 24 hours, which should be more than enough time unless the backlog of files becomes
    # large enough that they could wait longer than that.
    MetadataListener::Job.perform_later(
      path: [file_data['storage'], file_data['id']].join('/'),
      endpoint: FileUploader.api_endpoint(record),
      api_token: ExternalApp.metadata_listener.token,
      services: [:virus, :extracted_text]
    )
  end

  Attacher.destroy_block do
    Shrine::DestructionJob.perform_later(
      data: data
    )
  end

  class UploadedFile
    def virus
      metadata.dig('virus', 'status')
    end

    def md5
      metadata.dig('md5')
    end

    def sha256
      metadata.dig('sha256')
    end
  end
end
