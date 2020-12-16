# frozen_string_literal: true

class CatalogController < ApplicationController
  include Blacklight::Catalog

  # @note pass the current user in the @context hash of Blacklight::SearchService which allows the SearchBuilder to have
  # access to the current user in order to enforce access controls in Solr queries.
  def search_service_context
    { current_user: current_user }
  end

  def index
    (@response, _document_list) = search_service.search_results

    respond_to do |format|
      format.html { store_preferred_view }
      format.json do
        @presenter = Blacklight::JsonPresenter.new(@response, blacklight_config)
      end
    end
  end

  configure_blacklight do |config|
    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response
    #
    ## Should the raw solr document endpoint (e.g. /catalog/:id/raw) be enabled
    # config.raw_endpoint.enabled = false

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      rows: 10
    }

    # solr path which will be added to solr base url before the other solr params.
    # config.solr_path = 'select'
    # config.document_solr_path = 'get'

    # items to show per page, each number in the array represent another option to choose from.
    # config.per_page = [10,20,50,100]

    # solr field configuration for search results/index views
    config.index.title_field = 'title_tesim'
    # config.index.display_type_field = 'format'
    # config.index.thumbnail_field = 'thumbnail_path_ss'

    config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)

    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)

    config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    config.add_show_tools_partial(:citation)

    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

    # solr field configuration for document/show views
    # config.show.title_field = 'title_tesim'
    # config.show.display_type_field = 'format'
    # config.show.thumbnail_field = 'thumbnail_path_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to
    # have facet prefix-based navigation (useful when user clicks "more"
    # on a large facet and wants to navigate alphabetically across a
    # large set of results) :index_range can be an array or range of
    # prefixes that will be used to create the navigation (note: It is
    # case sensitive when searching values)

    config.add_facet_field 'display_work_type_ssi', label: I18n.t('catalog.facets.display_work_type_ssi'), limit: true
    config.add_facet_field 'keyword_sim', label: I18n.t('catalog.facets.keyword_sim'), limit: true
    config.add_facet_field 'subject_sim', label: I18n.t('catalog.facets.subject_sim'), limit: true
    config.add_facet_field 'creators_sim', label: I18n.t('catalog.facets.creators_sim'), limit: true

    # Example pivot facet
    # config.add_facet_field 'example_pivot_field', label: 'Pivot Field', pivot: ['format', 'language_ssim']

    # Example query facet field
    # config.add_facet_field 'example_query_facet_field', label: 'Publish Date', query: {
    #   years_5: { label: 'within 5 Years', fq: "pub_date_ssim:[#{Time.zone.now.year - 5} TO *]" },
    #   years_10: { label: 'within 10 Years', fq: "pub_date_ssim:[#{Time.zone.now.year - 10} TO *]" },
    #   years_25: { label: 'within 25 Years', fq: "pub_date_ssim:[#{Time.zone.now.year - 25} TO *]" }
    # }

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'title_tesim', label: 'Title'
    config.add_index_field 'creator_aliases_tesim', label: 'Creators'
    config.add_index_field 'aasm_state_tesim', label: 'Status'
    config.add_index_field 'keyword_tesim', label: 'Keywords'
    config.add_index_field 'work_type_ssim', label: 'Work Type'
    config.add_index_field 'deposited_at_dtsi', label: 'Date Deposited', helper_method: :date_display

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'title_tesim', label: 'Title'
    config.add_show_field 'work_type_ssim', label: 'Work Type'
    config.add_show_field 'aasm_state_tesim', label: 'Status'
    config.add_show_field 'keyword_tesim', label: 'Keywords'
    config.add_show_field 'subtitle_tesim', label: 'Subtitle'
    config.add_show_field 'rights_tesim', label: 'Rights'
    config.add_show_field 'description_tesim', label: 'Description'
    config.add_show_field 'contributor_tesim', label: 'Contributor'
    config.add_show_field 'publisher_tesim', label: 'Publisher'
    config.add_show_field 'published_date_tesim', label: 'Published Date'
    config.add_show_field 'subject_tesim', label: 'Subject'
    config.add_show_field 'language_tesim', label: 'Language'
    config.add_show_field 'identifier_tesim', label: 'Identifier'
    config.add_show_field 'based_near_tesim', label: 'Based Near'
    config.add_show_field 'related_url_tesim', label: 'Related URL'
    config.add_show_field 'source_tesim', label: 'Source'
    config.add_show_field 'version_number_isi', label: 'Version Number'
    config.add_show_field 'version_name_tesim', label: 'Version Name'
    config.add_show_field 'deposited_at_dtsi', label: 'Date Deposited'
    config.add_show_field 'updated_at_dtsi', label: 'Last Updated'
    config.add_show_field 'creator_aliases_tesim'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    config.add_search_field 'all_fields', label: 'All Fields'

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = {
        'spellcheck.dictionary': 'title',
        qf: '${title_qf}',
        pf: '${title_pf}'
      }
    end

    config.add_search_field('author') do |field|
      field.solr_parameters = {
        'spellcheck.dictionary': 'author',
        qf: '${author_qf}',
        pf: '${author_pf}'
      }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('subject') do |field|
      field.qt = 'search'
      field.solr_parameters = {
        'spellcheck.dictionary': 'subject',
        qf: '${subject_qf}',
        pf: '${subject_pf}'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, deposited_at_dtsi desc', label: 'relevance'
    config.add_sort_field 'title_tesim asc', label: 'title'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'
    # if the name of the solr.SuggestComponent provided in your solrcongig.xml is not the
    # default 'mySuggester', uncomment and provide it below
    # config.autocomplete_suggester = 'mySuggester'
  end
end
