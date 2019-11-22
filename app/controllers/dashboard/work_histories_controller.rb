# frozen_string_literal: true

module Dashboard
  class WorkHistoriesController < BaseController
    def show
      work = current_user.works.find(params[:work_id])
      @work_history = WorkHistoryPresenter.new(work)
    end
  end
end
