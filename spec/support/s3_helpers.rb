# frozen_string_literal: true

class S3Helpers
  # @param file [Pathname, File, IO]
  # @return [String] json component for ingesting a file into Scholarsphere
  # @note This short-cuts the request cycle to upload a file into Scholarsphere. Typically, the file data is posted to a
  # pre-signed url in S3, and then a final request is created consisting of the file's location in the S3 bucket, as
  # well as some additional metadata that Shrine will use. Here, we are creating a component part of that last request
  # by uploading the file directly into S3 (bypassing the pre-signed url + post process) and returning a hash which can
  # be incorporated into the ingest request to Scholarsphere.
  def self.shrine_upload(file:, storage: Scholarsphere::ShrineConfig::CACHE_PREFIX)
    path = Pathname.new(file)
    id = "#{SecureRandom.uuid}#{path.extname}"
    key = "#{storage}/#{id}"
    options = Api::V1::UploadsController.new.send(:s3_options)
    client = Aws::S3::Client.new(options)

    client.put_object(body: path.to_s, bucket: ENV['AWS_BUCKET'], key: key)

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
end
