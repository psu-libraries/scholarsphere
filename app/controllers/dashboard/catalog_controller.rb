# frozen_string_literal: true

module Dashboard
  class CatalogController < BaseController
    include Blacklight::Catalog

    # @note pass the current user in the @context hash of Blacklight::SearchService which allows the SearchBuilder to
    # have access to the current user in order to enforce access controls in Solr queries.
    def search_service_context
      { current_user: current_user }
    end

    copy_blacklight_config_from(::CatalogController)

    # @note We want to use Blacklight's views and override them locally, but that wasn't working because of the module
    # namespace. To fix this, we spell them out explicity.
    def self._prefixes
      ['application', 'dashboard/catalog', 'catalog']
    end

    configure_blacklight do |config|
      config.search_builder_class = SearchBuilder

      config.index.display_type_field = 'model_ssi'

      # Reset the facet configuration inherited from CatalogController
      config.facet_fields = {}

      config.add_facet_field 'aasm_state_tesim', label: I18n.t('catalog.facets.aasm_state_tesim'), collapse: false
      config.add_facet_field 'visibility_ssi', label: I18n.t('catalog.facets.visibility_ssi'), collapse: false

      config.add_facet_field 'embargoed_until_dtsi', label: I18n.t('catalog.facets.embargoed_until_dtsi'), query: {
        year_1: {
          label: I18n.t('catalog.facets.embargoed_until.year_1'),
          fq: 'embargoed_until_dtsi:[NOW TO NOW+1YEAR]'
        },
        year_5: {
          label: I18n.t('catalog.facets.embargoed_until.year_5'),
          fq: 'embargoed_until_dtsi:[NOW+1YEAR TO NOW+5YEAR]'
        },
        year_10: {
          label: I18n.t('catalog.facets.embargoed_until.year_10'),
          fq: 'embargoed_until_dtsi:[NOW+5YEAR TO NOW+10YEAR]'
        },
        year_more: {
          label: I18n.t('catalog.facets.embargoed_until.year_more'),
          fq: 'embargoed_until_dtsi:[NOW+10YEAR TO *]'
        }
      }, collapse: false

      config.add_facet_field 'display_work_type_ssi', label: I18n.t('catalog.facets.display_work_type_ssi'), limit: true
      config.add_facet_field 'keyword_sim', label: I18n.t('catalog.facets.keyword_sim'), limit: true
      config.add_facet_field 'subject_sim', label: I18n.t('catalog.facets.subject_sim'), limit: true
      config.add_facet_field 'creators_sim', label: I18n.t('catalog.facets.creators_sim'), limit: true
      config.add_facet_field 'migration_errors_sim', label: I18n.t('catalog.facets.migration_errors_sim'), limit: true

      # Reset the sort fields configuration inherited from CatalogController
      config.sort_fields = {}

      config.add_sort_field 'updated_at_dtsi desc', label: 'most recent'
      config.add_sort_field 'score desc', label: 'relevance'
      config.add_sort_field 'title_tesim asc', label: 'title'
    end
  end
end
