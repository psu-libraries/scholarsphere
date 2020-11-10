# frozen_string_literal: true

class PagesController < ApplicationController
  def home
    @featured_resources = resources.map { |resource| ResourceDecorator.decorate(resource) }
  end

  private

    def resources
      FeaturedResource
        .includes(:resource)
        .order(updated_at: :desc)
        .limit(3)
        .map(&:resource)
    end
end
