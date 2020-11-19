# frozen_string_literal: true

class SitemapSearchBuilder < SearchBuilder
  self.default_processor_chain += %i(
    build_sitemap_query
  )

  # @note Builds a Solr query to return all the UUIDs that begin with #access_id
  def build_sitemap_query(solr_parameters)
    solr_parameters[:fl] = 'id, timestamp'
    solr_parameters[:q] = "{!prefix f=uuid_ssi v=#{access_id}}"
    solr_parameters[:rows] = max_documents
    solr_parameters[:facet] = false
    solr_parameters[:defType] = 'lucene'
  end

  private

    def access_id
      @scope.context[:access_id]
    end

    def max_documents
      @scope.context[:max_documents]
    end
end
