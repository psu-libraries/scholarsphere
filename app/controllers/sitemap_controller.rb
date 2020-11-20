# frozen_string_literal: true

# @abstract Returns a auto-generated sitemap for a crawler. URLs are distributed across different pages depending on
# which hexadecimal character(s) their UUID begins with.

class SitemapController < ApplicationController
  def index
    @access_list = access_list
  end

  def show
    (@response, _deprecated_document_list) = search_service.search_results
  end

  private

    # @note This assumes all of our UUIDs are equally distributed so that there's at least one UUID that begins with
    # each hexadecimal character. This may not be the case, and some characters may have none or more UUIDs than
    # another.
    def access_list
      [*('a'..'f'), *('0'..'9')]
    end

    def search_service
      @search_service ||= ::Blacklight::SearchService.new(
        config: Blacklight::Configuration.new,
        search_builder_class: SitemapSearchBuilder,
        current_user: User.guest,
        access_id: params.require(:id),
        max_documents: max_documents
      )
    end

    def max_documents
      Rails.cache.fetch('index_max_docs', expires_in: 1.day) do
        Blacklight.default_index.connection.select(params: { q: '*:*', rows: 0 })['response']['numFound']
      end
    end
end
