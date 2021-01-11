# frozen_string_literal: true

module Dashboard
  class SearchBuilder < Blacklight::SearchBuilder
    include Blacklight::Solr::SearchBuilderBehavior

    self.default_processor_chain += %i(
      main_query
      apply_gated_edit
      log_solr_parameters
    )

    def main_query(solr_parameters)
      solr_parameters[:fq] ||= []
      latest_work_versions = '({!terms f=model_ssi}WorkVersion AND {!terms f=latest_version_bsi}true})'
      collections = '({!terms f=model_ssi}Collection)'
      solr_parameters[:fq] << "(#{latest_work_versions} OR #{collections})"
    end

    def apply_gated_edit(solr_parameters)
      return if current_user.admin?

      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << gated_edit_filters.compact.join(' OR ')
    end

    def log_solr_parameters(solr_parameters)
      Rails.logger.debug("Solr parameters: #{solr_parameters.inspect}")
    end

    private

      def gated_edit_filters
        [
          :apply_group_permissions,
          :apply_user_permissions,
          :apply_depositor_access,
          :apply_proxy_access
        ].map do |method|
          send(method)
        end
      end

      # For groups
      # @return [String] a lucence syntax term query suitable for :fq
      # @example "({!terms f=edit_groups_ssim}public,faculty,africana-faculty,registered)"
      def apply_group_permissions
        groups = current_user.groups
        return if groups.empty?

        "({!terms f=edit_groups_ssim}#{groups.map(&:name).join(',')})"
      end

      # For individual user access
      # @return [String] a lucence syntax term query suitable for :fq
      # @example 'edit_access_person_ssim:user_1@abc.com'
      def apply_user_permissions
        escape_filter('edit_users_ssim', current_user.access_id)
      end

      def apply_depositor_access
        "{!terms f=depositor_id_isi}#{current_user.actor.id}"
      end

      def apply_proxy_access
        "{!terms f=proxy_id_isi}#{current_user.actor.id}"
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
end
