# frozen_string_literal: true

class FileHelpers
  class << self
    def fixture_file(filename)
      Pathname.new(RSpec.configuration.fixture_path).join(filename)
    end

    def text_file
      file = Tempfile.new(['', '.txt'])
      file.binmode
      file.write(Faker::String.random)
      file.close
      Pathname.new(file)
    end

    # @param file [Pathname, File, IO]
    # @return [String] json component for ingesting a file into Scholarsphere
    # @note This short-cuts the request cycle to upload a file into Scholarsphere. Typically, the file data is posted to
    # a pre-signed url in S3, and then a final request is created consisting of the file's location in the S3 bucket, as
    # well as some additional metadata that Shrine will use. Here, we are creating a component part of that last request
    # by uploading the file directly into S3 (bypassing the pre-signed url + post process) and returning a hash which
    # can be incorporated into the ingest request to Scholarsphere.
    def shrine_upload(file:, storage: Scholarsphere::ShrineConfig::CACHE_PREFIX)
      source = Pathname.new(file)
      id = "#{SecureRandom.uuid}#{source.extname}"
      key = "#{storage}/#{id}"
      options = Api::V1::UploadsController.new.send(:s3_options)
      client = Aws::S3::Client.new(options)

      source.open do |body|
        client.put_object(bucket: ENV['AWS_BUCKET'], key: key, body: body)
      end

      {
        id: id,
        storage: storage,
        metadata: {
          size: file.size,
          filename: file.basename.to_s,
          mime_type: Marcel::MimeType.for(file)
        }
      }
    end

    def pdf_data(file_name)
      attacher = Shrine::Attacher.new
      attacher.set(uploaded_pdf(file_name))

      JSON.parse(attacher.column_data)
    end

    def uploaded_pdf(file_name)
      path = Rails.root.join('spec', 'fixtures', 'ipsum.pdf')
      file = File.open(path, binmode: true)
      file_size = file.size

      uploaded_file = Shrine.upload(file, :store, metadata: false)
      uploaded_file.metadata.merge!(
        'size' => file_size,
        'mime_type' => 'application/pdf',
        'filename' => file_name
      )

      uploaded_file
    end

    def doc_data(file_name)
      attacher = Shrine::Attacher.new
      attacher.set(uploaded_doc(file_name))
    end

    def uploaded_doc(file_name)
      path = Rails.root.join('spec', 'fixtures', 'future.docx')
      file = File.open(path, binmode: true)
      file_size = file.size

      uploaded_file = Shrine.upload(file, :store, metadata: false)
      uploaded_file.metadata.merge!(
        'size' => file_size,
        'mime_type' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'filename' => file_name
      )

      uploaded_file
    end

    # @note See https://github.com/shrinerb/shrine/blob/master/doc/testing.md#test-data
    def image_data(file_name)
      attacher = Shrine::Attacher.new
      attacher.set(uploaded_image(file_name))

      JSON.parse(attacher.column_data)
    end

    def uploaded_image(file_name)
      path = Rails.root.join('spec', 'fixtures', 'image.png')
      file = File.open(path, binmode: true)
      file_size = file.size

      # for performance we skip metadata extraction and assign test metadata
      uploaded_file = Shrine.upload(file, :store, metadata: false)
      uploaded_file.metadata.merge!(
        'size' => file_size,
        'mime_type' => 'image/png',
        'filename' => file_name
      )

      uploaded_file
    end
  end
end
