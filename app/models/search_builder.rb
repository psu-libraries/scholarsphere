# frozen_string_literal: true

# @abstract This is the main public search query. Both collections and publicly discoverable works are returned. Draft,
# embargoed, or withdrawn works, even if they are public, are not available. Collections with no published work are
# considered empty and are not available either.

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include CatalogSearchBehavior

  self.default_processor_chain += %i(
    search_related_files
    restrict_search_to_works_and_collections
    apply_gated_discovery
    limit_to_public_resources
    limit_to_published_resources
    exclude_empty_collections
  )

  def apply_gated_discovery(solr_parameters)
    return if current_user.admin?

    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << gated_discovery_filters.compact.join(' OR ')
  end

  # Overrides where method to allow passing in a string, as well as a Hash
  # https://github.com/projectblacklight/blacklight/blob/main/lib/blacklight/search_builder.rb
  def where(conditions)
    params_will_change!
    @search_state = @search_state.reset(@search_state.params.merge(q: conditions))
    @blacklight_params = @search_state.params.dup
    @additional_filters = conditions if conditions.is_a?(Hash)
    self
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
end
