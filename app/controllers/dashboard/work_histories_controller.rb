# frozen_string_literal: true

module Dashboard
  class WorkHistoriesController < BaseController
    def show
      @work = policy_scope(Work).find(params[:work_id])
      @latest_work_version = WorkVersionDecorator.new(@work.latest_version)
    end
  end
end
