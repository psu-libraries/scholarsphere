# frozen_string_literal: true

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior

  self.default_processor_chain += [:show_works_only]

  def show_works_only(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << 'model_ssi:Work'
  end
end
