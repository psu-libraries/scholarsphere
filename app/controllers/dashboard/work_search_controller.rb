# frozen_string_literal: true

class Dashboard::WorkSearchController < Dashboard::BaseController
  def index
    query = "#{params[:q]}*"
    max_documents = params[:max_documents].present? ? params[:max_documents].to_i : 50

    (member_works, _deprecated_document_list) = search_service(query, max_documents).search_results

    results = member_works.documents.map { |d| { id: d.work_id, text: d.title } }

    render json: results
  end

  private

    def search_service(query, max_documents)
      @search_service ||= ::Blacklight::SearchService.new(
        config: Blacklight::Configuration.new,
        search_builder_class: Dashboard::MemberWorksSearchBuilder,
        current_user: current_user,
        max_documents: max_documents,
        user_params: { q: query }
      )
    end
end
