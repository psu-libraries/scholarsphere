# frozen_string_literal: true

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior

  self.default_processor_chain += %i(
    restrict_search_to_works
    apply_gated_discovery
    exclude_embargoed_works
    log_solr_parameters
  )

  def restrict_search_to_works(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << 'model_ssi:Work'
  end

  def apply_gated_discovery(solr_parameters)
    return if current_user.admin?

    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << gated_discovery_filters.compact.join(' OR ')
  end

  def log_solr_parameters(solr_parameters)
    Rails.logger.debug("Solr parameters: #{solr_parameters.inspect}")
  end

  def exclude_embargoed_works(solr_parameters)
    return if current_user.admin?

    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << '-embargoed_until_dtsi:[NOW TO *]'
  end

  private

    def gated_discovery_filters
      [:apply_group_permissions, :apply_user_permissions].map do |method|
        send(method)
      end
    end

    # For groups
    # @return [String] a lucence syntax term query suitable for :fq
    # @example "({!terms f=discover_groups_ssim}public,faculty,africana-faculty,registered)"
    def apply_group_permissions
      groups = current_user.groups
      return if groups.empty?

      "({!terms f=discover_groups_ssim}#{groups.map(&:name).join(',')})"
    end

    # For individual user access
    # @return [String] a lucence syntax term query suitable for :fq
    # @example 'discover_access_person_ssim:user_1@abc.com'
    def apply_user_permissions
      return if current_user.guest?

      escape_filter('discover_users_ssim', current_user.access_id)
    end

    def current_user
      @current_user ||= @scope.context[:current_user]
    end

    def escape_filter(key, value)
      [key, escape_value(value)].join(':')
    end

    def escape_value(value)
      RSolr.solr_escape(value).gsub(/ /, '\ ')
    end
end
