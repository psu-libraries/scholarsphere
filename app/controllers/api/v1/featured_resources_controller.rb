# frozen_string_literal: true

module Api::V1
  class FeaturedResourcesController < RestController
    def create
      if update_or_create
        render json: { message: "Processed resource #{resource.uuid}" }, status: status
      else
        render json: 'Unable to feature this resource', status: :unprocessable_entity
      end
    end

    private

      attr_reader :status

      def update_or_create
        FeaturedResource.find_by!(resource_uuid: resource.uuid).update(updated_at: Time.zone.now)
        @status = :ok
      rescue ActiveRecord::RecordNotFound
        FeaturedResource.create(resource: resource, resource_uuid: resource.uuid)
        @status = :created
      end

      def resource
        @resource ||= FindResource.call(params.require(:uuid))
      end
  end
end
