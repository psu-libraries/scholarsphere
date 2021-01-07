# frozen_string_literal: true

module Dashboard
  class MemberWorksSearchBuilder < SearchBuilder
    # @note Builds a Solr query to return a list of all the works a user may add to a collection
    def main_query(solr_parameters)
      solr_parameters[:fl] = 'work_id_isi, title_tesim'
      solr_parameters[:fq] << '{!terms f=model_ssi}Work'
      solr_parameters[:rows] = max_documents
      solr_parameters[:facet] = false
    end

    private

      def max_documents
        @scope.context[:max_documents]
      end
  end
end
