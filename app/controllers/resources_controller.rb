# frozen_string_literal: true

class ResourcesController < ApplicationController
  def show
    @resource = ResourceDecorator.new(find_resource(params[:id]))
    authorize @resource
    @resource.count_view! unless browser.bot?
  end

  private

    def find_resource(uuid)
      FindResource.call(uuid)
    end
end
