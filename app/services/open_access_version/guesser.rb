# frozen_string_literal: true

require 'pdf-reader'

class OpenAccessVersion::Guesser
  # The OpenAccessVersion::Guesser attempts to determine whether a WorkVersion's
  # PDF file(s) indicate that the WorkVersion is an accepted or published version.
  # It does this with three steps in preferential order:
  #   1. Check for version signals in the PDF's EXIF metadata
  #   2. Check for an arXiv watermark in the PDF's content which indicates an accepted version
  #   3. Check for version signals in the PDF's content and filename using the OpenAccessVersion::ScoreCalculator

  ACCEPTED_VERSION_VALUE = 'accepted'
  PUBLISHED_VERSION_VALUE = 'published'

  def initialize(work_version:)
    @work_version = work_version
  end

  def version
    score = 0

    work_version.file_resources.each do |file_resource|
      # exif_result = OpenAccessVersion::ExifChecker
      #   .new(file_path: file_resource.file.path,
      #        journal: work_version.journal).version

      # return exif_result if exif_result.present?

      next unless pdf_file?(file_resource)

      filename = detected_filename(file_resource)

      file_resource.file.open do |io|
        pdf_reader = pdf_reader(io)
        if contains_arxiv_watermark?(pdf_reader)
          return ACCEPTED_VERSION_VALUE
        end

        score += OpenAccessVersion::ScoreCalculator.new(
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
