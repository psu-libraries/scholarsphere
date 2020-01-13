# frozen_string_literal: true

module Dashboard
  class WorkHistoriesController < BaseController
    def show
      @work = current_user.works.find(params[:work_id])
      @latest_work_version = Dashboard::WorkVersionDecorator.new(@work.latest_version)
    end
  end
end
