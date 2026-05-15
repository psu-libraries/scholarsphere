# frozen_string_literal: true

require 'exiftool_vendored'

module OpenAccessVersion
  class ExifChecker
    PUBLISHED_VERSION_CREATORS = ['indesign', 'arbortext',
                                  'elsevier', 'springer'].freeze
    RIGHTS_EN_GB_TEXT = 'Not for further distribution unless allowed by the License ' \
                        'or with the express written permission of Cambridge University Press.'

    def initialize(io:, publisher:)
      @io = io
      @publisher = publisher
    end

    def version
      @version ||= determine_version
    end

    private

      def determine_version
        return if exif.blank?
        return VersionValues::ACCEPTED if accepted?
        return VersionValues::PUBLISHED if published?

        # LaTeX formats papers like a published version, but it's often used
        # for both accepted and published versions. This makes it too confusing
        # for our checker to determine, so default to nil.
        nil if latex?
      end

      def exif
        @io.rewind if @io.respond_to?(:rewind)
        @exif ||= Exiftool.new(@io).to_hash
      end

      def latex?
        (!exif[:creator].nil? && exif[:creator].to_s.downcase.include?('latex')) ||
          (!exif[:creator_tool].nil? && exif[:creator_tool].to_s.downcase.include?('latex'))
      end

      def accepted?
        exif[:journal_article_version]&.downcase == 'am'
      end

      def published?
        exif[:journal_article_version]&.downcase == 'p' ||
          exif[:journal_article_version]&.downcase == 'vor' ||
          rights_en_gb? ||
          wps_journaldoi? ||
          subject? ||
          rendition_class? ||
          creator? ||
          creator_tool? ||
          producer?
      end

      def rights_en_gb?
        !exif[:rights_en_gb].nil? and
          exif[:rights_en_gb] == RIGHTS_EN_GB_TEXT
      end

      def wps_journaldoi?
        !exif[:wps_journaldoi].nil?
      end

      def subject?
        subjects = ['downloaded from', 'journal pre-proof']
        subjects << @publisher unless @publisher.nil?
        if exif[:subject].present? && exif[:subject].is_a?(Array)
          subjects.any? { |s| exif[:subject]&.any? { |exs| exs.to_s.downcase.include? s } }
        elsif exif[:subject].present? && exif[:subject].is_a?(String)
          subjects.any? { |s| exif[:subject].downcase.include? s }
        else
          false
        end
      end

      def rendition_class?
        exif[:rendition_class] == 'proof:pdf'
      end

      def creator?
        includes_published_creator?(exif[:creator])
      end

      def creator_tool?
        includes_published_creator?(exif[:creator_tool])
      end

      def producer?
        exif[:producer] == 'Project MUSE'
      end

      def includes_published_creator?(value)
        normalized = value.to_s.downcase
        PUBLISHED_VERSION_CREATORS.any? { |creator| normalized.include?(creator) }
      end
  end
end
