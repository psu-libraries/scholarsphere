# frozen_string_literal: true

# @abstract This controller is used exclusively to render only an html snippet that is appended to the works
# portion of the collection form

module Dashboard
  module Form
    class WorkMembershipsController < BaseController
      def new
        work_membership = CollectionWorkMembership.new(work: work)
        render partial: 'dashboard/form/members/work_membership_fields',
               locals: { work_membership: work_membership }
      end

      private

        def work
          Work.find(work_membership_params[:work_id])
        end

        def work_membership_params
          params
            .permit(
              :work_id
            )
        end
    end
  end
end
