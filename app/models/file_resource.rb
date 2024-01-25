# frozen_string_literal: true

class FileResource < ApplicationRecord
  include FileUploader::Attachment(:file)
  include DepositedAtTimestamp
  include ViewStatistics
  include GeneratedUuids

  attr_writer :indexing_source

  has_many :file_version_memberships, dependent: :destroy
  has_many :work_versions, through: :file_version_memberships

  has_many :legacy_identifiers,
           as: :resource,
           dependent: :destroy

  has_one :thumbnail_upload,
          required: false,
          dependent: :destroy

  after_commit :perform_update_index, on: [:create, :update]

  def self.reindex_all(relation: all, async: false)
    relation.find_each do |file|
      if async
        SolrIndexingJob.perform_later(file, commit: false)
      else
        SolrIndexingJob.perform_now(file, commit: false)
      end
    end
    IndexingService.commit
  end

  # @param [String, Symbol, Array]
  def self.find_by_mime_type(types)
    FindByMimeType.call(mime_types: types)
  end

  # @note Using `head_object` will retrieve the metadata without retrieving the entire object.
  def etag
    @etag ||= client
      .head_object(bucket: ENV['AWS_BUCKET'], key: "#{file_data['storage']}/#{file_data['id']}")
      .etag
      .gsub('"', '')
  rescue Aws::S3::Errors::Forbidden
    '[unavailable]'
  end

  # @note Shrine is returning ASCII-8BIT encoding, but we can safely assume it is UTF-8
  def extracted_text
    @extracted_text ||= file_derivatives.fetch(:text, StringIO.new)
      .read
      .force_encoding('UTF-8')
  end

  def to_solr
    document_builder.generate(resource: self)
  end

  def update_index(commit: true)
    IndexingService.add_document(to_solr, commit: commit)
  end

  def indexing_source
    @indexing_source ||= SolrIndexingJob.public_method(:perform_later)
  end

  def thumbnail_url
    file_attacher.url(:thumbnail)
  end

  def thumbnailable?
    mime_type = file_data.dig('metadata', 'mime_type') || ''
    return true if mime_type.include?('image')
    return true if mime_type == 'application/pdf'
    return true if mime_type == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'

    false
  end

  private

    def client
      @client ||= Aws::S3::Client.new
    end

    def document_builder
      SolrDocumentBuilder.new(
        FileResourceSchema
      )
    end

    def perform_update_index
      indexing_source.call(self)
    end
end
