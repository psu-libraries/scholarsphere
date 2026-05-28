# frozen_string_literal: true

class OawPermissionsClient
  class InvalidVersion < StandardError; end
  attr_reader :doi, :version

  def all_permissions
    return @all_permissions if defined?(@all_permissions)

    @all_permissions = JSON.parse(permissions_response)['all_permissions']
  rescue JSON::ParserError
    @all_permissions = nil
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
          .select { |perm| perm if perm['version'] == OpenAccessVersion::VersionValues::ACCEPTED }
          .first
          .presence || {}
      else
        {}
      end
    end

    def published_version
      if all_permissions.present?
        all_permissions
          .select { |perm| perm if perm['version'] == OpenAccessVersion::VersionValues::PUBLISHED }
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
      WorkVersion::Licenses.options_for_select_box.pluck(1)
    end
end
