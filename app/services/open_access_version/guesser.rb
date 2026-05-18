# frozen_string_literal: true

require 'pdf-reader'

module OpenAccessVersion
  class Guesser
    # The OpenAccessVersion::Guesser attempts to determine whether a WorkVersion's
    # PDF or docx file(s) indicate that the WorkVersion is an accepted, published, or unknown
    # version.  It does this with three steps in order of precedence:
    #   1. Check for version signals in the PDFs' or docx files' EXIF metadata
    #   2. Check for an arXiv watermark in the PDFs' content
    #   3. Check for version signals in the PDFs' content and filename using the
    #      OpenAccessVersion::ScoreCalculator.  The score is accumulated across all PDF files
    #

    def initialize(work_version:)
      @work_version = work_version
    end

    def version
      score = 0

      work_version.file_resources.each do |file_resource|
        next unless file_resource.pdf? || file_resource.docx?

        file_download = file_resource.file.download

        exif_result = ExifChecker.new(file_path: file_download.path,
                                      publisher: work_version.publisher).version

        return exif_result if exif_result.present?

        next unless file_resource.pdf?

        pdf_reader = pdf_reader(file_download.path)

        if contains_arxiv_watermark?(pdf_reader)
          return VersionValues::ACCEPTED
        end

        filename = detected_filename(file_resource)

        score += ScoreCalculator.new(
          work_version: work_version,
          pdf_reader: pdf_reader,
          filename: filename
        ).score

        file_download.close!
      end

      if score.positive?
        VersionValues::PUBLISHED
      elsif score.negative?
        VersionValues::ACCEPTED
      else
        VersionValues::UNKNOWN
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
        uri = pdf_reader&.objects&.[](8)&.[](:A)&.[](:URI)
        uri&.include?('arxiv.org')
      end

      def detected_filename(file_resource)
        file_resource.file&.original_filename.to_s
      end
  end
end
