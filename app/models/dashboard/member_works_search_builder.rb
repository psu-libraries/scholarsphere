# frozen_string_literal: true

# @abstract Builds a search query that returns a list of all the work titles a user may add to a collection. Available
# works are any publicly accessible work that the user as edit access to. Draft or withdrawn works, even if editable by
# the user, are not returned.

module Dashboard
  class MemberWorksSearchBuilder < Blacklight::SearchBuilder
    include Blacklight::Solr::SearchBuilderBehavior
    include CatalogSearchBehavior

    self.default_processor_chain += %i(
      restrict_search_to_work_titles
      apply_gated_edit
      limit_to_public_resources
      exclude_withdrawn_resources
    )

    # @note Builds a Solr query to return a list of all the works a user may add to a collection
    def restrict_search_to_work_titles(solr_parameters)
      solr_parameters[:fq] ||= []

      solr_parameters[:fl] = 'work_id_isi, title_tesim'
      solr_parameters[:fq] << '{!terms f=model_ssi}Work'
      solr_parameters[:rows] = max_documents
      solr_parameters[:facet] = false
      solr_parameters[:qf] = 'title_tesim'
    end

    private

      def max_documents
        @scope.context[:max_documents]
      end
  end
end
