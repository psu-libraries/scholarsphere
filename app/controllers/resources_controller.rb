# frozen_string_literal: true

class ResourcesController < ApplicationController
  def show
    # @todo authorization
    @resource = find_resource(params[:id])
  end

  private

    # @todo probably a good idea to make this into a ResourceFinder class
    def find_resource(uuid)
      Work.where(uuid: uuid).first ||
        WorkVersion.where(uuid: uuid).first ||
        raise(ActiveRecord::RecordNotFound)
    end
end
