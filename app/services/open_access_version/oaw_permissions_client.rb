# frozen_string_literal: true

module OpenAccessVersion
  class OawPermissionsClient
    class InvalidVersion < StandardError; end

    attr_reader :doi, :version

    private

      def permissions_response
        @response ||= Faraday.get(oaw_permissions_w_doi_url).body
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError
        ''
      end

      def oaw_permissions_w_doi_url
        oaw_permissions_base_url + CGI.escape(doi.to_s)
      end

      def oaw_permissions_base_url
        'https://bg.api.oa.works/permissions/'
      end

      def all_permissions
        return @all_permissions if defined?(@all_permissions)

        @all_permissions = JSON.parse(permissions_response)['all_permissions']
      rescue JSON::ParserError
        @all_permissions = nil
      end

      def best_permission
        return @best_permission if defined?(@best_permission)

        @best_permission = JSON.parse(permissions_response)['best_permission']
      rescue JSON::ParserError
        @best_permission = nil
      end

      def best_permission_version
        @best_permission['version'] if best_permission.present?
      end

      def accepted_version
        if best_permission_version == VersionValues::ACCEPTED
          best_permission
        elsif all_permissions.present?
          all_permissions
            .select { |perm| perm if perm['version'] == VersionValues::ACCEPTED }
            .first
            .presence || {}
        else
          {}
        end
      end

      def published_version
        if best_permission_version == VersionValues::PUBLISHED
          best_permission
        elsif all_permissions.present?
          all_permissions
            .select { |perm| perm if perm['version'] == VersionValues::PUBLISHED }
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
          rights[6]
        when 'other (non-commercial)', 'unclear', /other-closed/i, /none/i
          rights[11]
        end
      end

      def rights
        WorkVersion::Licenses.options_for_select_box.pluck(1)
      end
  end
end
