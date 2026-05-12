# frozen_string_literal: true

require 'pdf-reader'

class OpenAccessVersionGuesser
  ACCEPTED_VERSION_VALUE = 'accepted_version'
  PUBLISHED_VERSION_VALUE = 'published_version'

  def initialize(work_version:)
    @work_version = work_version
  end

  def version
    score = 0

    work_version.file_resources.each do |file_resource|
      next unless pdf_file?(file_resource)

      filename = detected_filename(file_resource)

      file_resource.file.open do |io|
        pdf_reader = pdf_reader(io)
        if contains_arxiv_watermark?(pdf_reader)
          return ACCEPTED_VERSION_VALUE
        end

        score += OpenAccessVersionScoreCalculator.new(
          work_version: work_version,
          pdf_reader: pdf_reader,
          filename: filename
        ).score
      end
    end

    if score.positive?
      PUBLISHED_VERSION_VALUE
    elsif score.negative?
      ACCEPTED_VERSION_VALUE
    end
  end

  private

    attr_reader :work_version

    def pdf_reader(file)
      PDF::Reader.new(file)
    rescue PDF::Reader::MalformedPDFError,
           PDF::Reader::InvalidObjectError,
           PDF::Reader::EncryptedPDFError
      nil
    end

    def contains_arxiv_watermark?(pdf_reader)
      if !pdf_reader.nil? && !pdf_reader.objects[8].nil? && !pdf_reader.objects[8][:A].nil? && !pdf_reader.objects[8][:A][:URI].nil?
        pdf_reader.objects[8][:A][:URI].include?('arxiv.org')
      end
    end

    def pdf_file?(file_resource)
      file_resource.file&.mime_type == FileResource::PDF_MIME_TYPE
    end

    def detected_filename(file_resource)
      file_resource.file&.original_filename.to_s
    end
end
