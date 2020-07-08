# frozen_string_literal: true

class ResourcesController < ApplicationController
  def show
    @resource = ResourceDecorator.new(find_resource(params[:id]))
    authorize @resource
    @resource.count_view! if count_view?
  end

  private

    def find_resource(uuid)
      FindResource.call(uuid)
    end

    def count_view?
      return false if browser.bot?

      SessionViewStatsCache.call(session: session, resource: @resource)
    end
end
