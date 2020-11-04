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
      config.response_model = Dashboard::PostgresResponse

      config.index.display_type_field = 'model_ssi'

      # Reset the facet configuration inherited from CatalogController
      config.facet_fields = {}

      config.add_facet_field 'aasm_state_tesim', label: 'Status', collapse: false
      config.add_facet_field 'visibility_ssi', label: 'Visibility', collapse: false

      config.add_facet_field 'embargoed_until_dtsi', label: 'Embargoed Date', query: {
        year_1: { label: 'this year', fq: 'embargoed_until_dtsi:[NOW TO NOW+1YEAR]' },
        year_5: { label: 'in 5 years', fq: 'embargoed_until_dtsi:[NOW+1YEAR TO NOW+5YEAR]' },
        year_10: { label: 'in 10 years', fq: 'embargoed_until_dtsi:[NOW+5YEAR TO NOW+10YEAR]' },
        year_more: { label: 'beyond 10 years', fq: 'embargoed_until_dtsi:[NOW+10YEAR TO *]' }
      }, collapse: false

      config.add_facet_field 'display_work_type_ssi', label: 'Work Type', limit: true
      config.add_facet_field 'keyword_sim', label: 'Keywords', limit: true
      config.add_facet_field 'subject_sim', label: 'Subject', limit: true
      config.add_facet_field 'creators_sim', label: 'Creators', limit: true
      config.add_facet_field 'migration_errors_sim', label: 'Migration Errors', limit: true
    end

    private

      def determine_layout
        'frontend'
      end
  end
end
