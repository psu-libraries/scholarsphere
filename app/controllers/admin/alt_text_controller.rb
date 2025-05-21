# frozen_string_literal: true

class Admin::AltTextController < ApplicationController
  before_action :set_file_resource

  # PATCH /dashboard/alt_text/:id
  def update
    @file_resource.file_attacher.add_metadata(alt_text: file_resource_params[:alt_text])
    if @file_resource.save
      render json: { success: true,
                     alt_text: @file_resource.file_data['metadata']['alt_text'] },
             status: :ok
    else
      logger.error(@file_resource.errors.full_messages)
      render json: { success: false,
                     errors: @file_resource.errors.full_messages,
                     alt_text: @file_resource.reload.file_data['metadata']['alt_text'] },
             status: :unprocessable_entity
    end
  end

  private

    def set_file_resource
      @file_resource = FileResource.find(params[:id])
    end

    def file_resource_params
      params.fetch(:file_resource).permit(:alt_text)
    end
end
