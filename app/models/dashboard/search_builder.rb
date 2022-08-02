# frozen_string_literal: true

# @abstract Builds a search query of all resources the user has edit access to. This is used to power the dashboard
# search interface. Empty collections, draft, embargoed, and withdrawn works are eligible if the user has edit access
# to them.

module Dashboard
  class SearchBuilder < Blacklight::SearchBuilder
    include Blacklight::Solr::SearchBuilderBehavior
    include CatalogSearchBehavior

    # Overrides where method to allow passing in a string, as well as a Hash
    # https://github.com/projectblacklight/blacklight/blob/main/lib/blacklight/search_builder.rb
    def where(conditions)
      params_will_change!
      @search_state = @search_state.reset(@search_state.params.merge(q: conditions))
      @blacklight_params = @search_state.params.dup
      @additional_filters = conditions if conditions.is_a?(Hash)
      self
    end

    self.default_processor_chain += %i(
      search_related_files
      restrict_search_to_works_and_collections
      apply_gated_edit
    )
  end
end
