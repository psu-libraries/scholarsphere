# frozen_string_literal: true

module Api::V1
  class DoisController < RestController
    def index
      results = DoiSearch.all
      render json: results
    end

    def show
      results = DoiSearch.new(doi: params[:doi]).results
      if results.any?
        render json: success_response(results)
      else
        head :not_found
      end
    end

    private

      def success_response(results)
        results.map do |uuid|
          { url: resource_path(uuid) }
        end
      end
  end
end
