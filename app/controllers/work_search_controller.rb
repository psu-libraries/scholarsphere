# frozen_string_literal: true

class WorkSearchController < ApplicationController
  def index
    query = params[:q]

    (member_works, _deprecated_document_list) = search_service(query).search_results

    results = member_works.documents.map { |d| { id: d.work_id, text: d.title } }

    render json: results
  end

  private

    def search_service(query)
      @search_service ||= ::Blacklight::SearchService.new(
        config: Blacklight::Configuration.new,
        search_builder_class: Dashboard::MemberWorksSearchBuilder,
        current_user: current_user,
        max_documents: 50,
        user_params: { q: query }
      )
    end
end
