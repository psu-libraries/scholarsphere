class WorkSearchController < ApplicationController
  def index 
    # /works?q=""
    query = params[:q]

    works = Work
      .includes(:versions)
      .limit(20)

    works_serialized = works
    .map { |w| { id: w.id, text: w.latest_published_version.title } }
    .reject { |h| !h[:text]&.include? query }

    render json: works_serialized
  end
end