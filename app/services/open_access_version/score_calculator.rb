# frozen_string_literal: true

module OpenAccessVersion
  class ScoreCalculator
    # The OpenAccessVersion::ScoreCalculator attepts to determine whether
    # a PDF's text content and filename indicate that the PDF is an
    # accepted or published version.  It does this by applying a set of rules
    # defined in a CSV file at config/open_access_version_guessing_rules.csv.
    # These rules and this code are tightly coupled so both should be considered
    # when making changes.

    # A positive score indicates the PDF is a published version,
    # a negative score indicates an accepted version, and a score
    # of zero indicates an unknown version.

    def initialize(work_version:, pdf_reader:, filename:)
      @work_version = work_version
      @pdf_reader = pdf_reader
      @filename = filename
    end

    def score
      return 0 if pdf_reader.nil?

      content = extract_content
      return 0 if content.empty?

      rules_lines.sum { |line| process_line(line, content) }
    end

    private

      attr_reader :filename, :pdf_reader, :work_version

      def extract_content
        words = []
        pdf_reader.pages.each do |page|
          break if words.count >= 500

          words << page.text.split.first(500)
          words.flatten!
        rescue StandardError
          # Formatting issues can cause page-level parsing errors.
          next
        end

        words.flatten.join(' ')
      rescue PDF::Reader::MalformedPDFError,
             PDF::Reader::InvalidObjectError,
             PDF::Reader::EncryptedPDFError
        ''
      end

      def rules_lines
        csv_path = File.join('config', 'open_access_version_guessing_rules.csv')

        if File.exist?(csv_path)
          CSV.parse(File.read(csv_path), headers: true)
        else
          raise "Error: #{csv_path} does not exist or cannot be read."
        end
      end

      def process_line(line, content)
        what_to_search = process_wts(line['what to search'])
        where_to_search = line['where to search']
        how_to_search = line['how to search']
        indication = line['what it Indicates']&.downcase

        matched = match_content(what_to_search, where_to_search, how_to_search, content)

        process_indication(indication, matched)
      end

      def process_wts(what_to_search)
        return what_to_search.strip unless what_to_search.include?('<<') && what_to_search.include?('>>')

        # The rules CSV will have matchers that look like <<placeholder>>
        # to specify placeholders like <<year>> that will
        # be replaced with metadata values from the WorkVersion.
        what_to_match = what_to_search.split('<<')[1].split('>>').first
        value = wv_metadata[what_to_match.downcase.to_sym]
        return what_to_search.strip if value.blank?

        what_to_search.gsub("<<#{what_to_match}>>", value.to_s).squish
      end

      def match_content(what_to_search, where_to_search, how_to_search, content)
        if how_to_search == 'string'
          if where_to_search == 'file'
            content.include?(what_to_search)
          else
            filename&.include?(what_to_search)
          end
        else
          regex = Regexp.new(what_to_search, 'im')
          if where_to_search == 'file'
            content.downcase.match?(regex)
          else
            filename&.match?(regex)
          end
        end
      end

      def process_indication(indication, matched)
        return 0 unless matched

        return 1 if ['publisher pdf', 'publishedversion'].include?(indication)

        -1
      end

      def wv_metadata
        # WorkVersion metadata that can be used in the rules CSV placeholders
        {
          year: work_version.published_date&.year,
          doi: work_version.identifier,
          publisher: work_version.publisher
        }
      end
  end
end
