# frozen_string_literal: true

class OawPermissionsClient
  class InvalidVersion < StandardError; end
  attr_reader :doi, :version

    VALID_VERSIONS = %w[
    acceptedVersion
    publishedVersion
  ].freeze #will need to pull from translation

      def all_permissions
        @all_permissions ||= JSON.parse(permissions_response)['all_permissions']
      rescue JSON::ParserError
        nil
      end

  private

    def permissions_response
      Faraday.get(oaw_permissions_w_doi_url).body
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError
      ''
    end

    def oaw_permissions_w_doi_url
      oaw_permissions_base_url + CGI.escape(doi.to_s)
    end

    def oaw_permissions_base_url
      'https://bg.api.oa.works/permissions/'
    end

    def accepted_version
      if all_permissions.present?
        all_permissions
          .select { |perm| perm if perm['version'] == 'acceptedVersion' } #will need to add to translation
          .first
          .presence || {}
      else
        {}
      end
    end

    def published_version
      if all_permissions.present?
        all_permissions
          .select { |perm| perm if perm['version'] == 'publishedVersion' } #will need to add to translation
          .first
          .presence || {}
      else
        {}
      end
    end

      def map_licence(string)
        return nil if string.nil?

        case string.downcase
        when 'cc-by', 'cc-by 3.0', 'cc-by 4.0'
        rights[0]
        when 'cc-by-nc'
        rights[2]
        when 'cc-by-nc-nd'
        rights[4]
        when 'cc-by-nc-sa'
        rights[5]
        when 'cc0'
        rights[7]
        when 'other (non-commercial)', 'unclear', /other-closed/i, /none/i
        rights[8]
        end
    end

      def rights
        rights_options.pluck(1)
      end

    def rights_options
        [
        ['Attribution 4.0 International (CC BY 4.0)', 'https://creativecommons.org/licenses/by/4.0/'],
        ['Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)', 'https://creativecommons.org/licenses/by-sa/4.0/'],
        ['Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)', 'https://creativecommons.org/licenses/by-nc/4.0/'],
        ['Attribution-NoDerivatives 4.0 International (CC BY-ND 4.0)', 'https://creativecommons.org/licenses/by-nd/4.0/'],
        ['Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)', 'https://creativecommons.org/licenses/by-nc-nd/4.0/'],
        ['Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)', 'https://creativecommons.org/licenses/by-nc-sa/4.0/'],
        ['Public Domain Mark 1.0', 'http://creativecommons.org/publicdomain/mark/1.0/'],
        ['CC0 1.0 Universal', 'http://creativecommons.org/publicdomain/zero/1.0/'],
        ['All rights reserved', 'https://rightsstatements.org/page/InC/1.0/']
        ]
    end
end