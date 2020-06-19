# frozen_string_literal: true

module Api::V1
  class FilesController < RestController
    def update
      if update_metadata
        render json: updated_response, status: :ok
      else
        render json: unprocessable_entity_response, status: :unprocessable_entity
      end
    end

    private

      def file_resource
        @file_resource ||= FileResource.find(params[:id])
      end

      def update_metadata
        file_resource.file_attacher.add_metadata(metadata_params)
        file_resource.file_attacher.write
        file_resource.save
      end

      def updated_response
        {
          message: 'File was successfully updated'
        }
      end

      def unprocessable_entity_response
        {
          message: 'Unable to complete the request',
          errors: file_resource.errors.full_messages
        }
      end

      def metadata_params
        params
          .require(:metadata)
          .permit(virus: [:status, :scanned_at])
      end
  end
end
