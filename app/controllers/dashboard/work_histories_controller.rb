# frozen_string_literal: true

module Dashboard
  class WorkHistoriesController < BaseController
    def show
      @work = Work.find(params[:work_id])
      authorize(@work)
      @latest_work_version = WorkVersionDecorator.new(@work.latest_version)
    end
  end
end
