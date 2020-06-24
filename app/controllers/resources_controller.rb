# frozen_string_literal: true

class ResourcesController < ApplicationController
  def show
    @resource = ResourceDecorator.new(find_resource(params[:id]))
    authorize @resource
    @resource.count_view! unless browser.bot?
  end

  private

    def find_resource(uuid)
      Work.where(uuid: uuid).first ||
        WorkVersion.where(uuid: uuid).first ||
        Collection.where(uuid: uuid).first ||
        raise(ActiveRecord::RecordNotFound)
    end
end
