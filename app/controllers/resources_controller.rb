# frozen_string_literal: true

class ResourcesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :resource_not_found

  def show
    @resource = ResourceDecorator.decorate(find_resource(params[:id]))
    authorize @resource
    @resource.count_view! if count_view?
  end

  def new_alternate_format_request
    file_version = FileVersionMembershipDecorator.new(FileVersionMembership.find(params[:id]))
    @request = AlternateFormatRequest.new(file_version, current_user)
    render 'alternate_format_request'
  end

  def create_alternate_format_request
    @request = AlternateFormatRequest.new
    @request.attributes = alternate_format_request_params
    @request.validate!
    LibanswersApiService.new.request_alternate_format(@request)
    redirect_to resource_path(params[:resource_id]), notice: I18n.t('resources.request_alternate_format_button.success_message')
  end

  private

    def find_resource(uuid)
      FindResource.call(uuid)
    end

    def count_view?
      return false if browser.bot?

      SessionViewStatsCache.call(session: session, resource: @resource)
    end

    helper_method :deposit_pathway
    def deposit_pathway
      @deposit_pathway ||= WorkDepositPathway.new(@resource)
    end

    def alternate_format_request_params
      params
        .require(:alternate_format_request)
        .permit(
          :email,
          :url,
          :message,
          :name,
          :title
        )
    end

    def resource_not_found(exception)
      if request.get? && request.path.match?(%r{^/resources/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$})
        Bugsnag.notify(exception, &:ignore!)
        head :not_found
      else
        raise exception
      end
    end
end
