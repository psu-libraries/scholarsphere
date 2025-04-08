# frozen_string_literal: true

class DepositorRequestService
  class RequestError < RuntimeError; end
  class InvalidResourceError < RuntimeError; end

  def initialize(resource)
    @resource = resource
  end

  def request_action(curation_requested)
    column = curation_requested ? :draft_curation_requested : :accessibility_remediation_requested
    @resource.update_column(column, true)
    #     # We want validation errors to block curation requests and keep users on the edit page
    #     # so WorkVersion needs to temporarily act like it's being published. It's returned to it's
    #     # initial state before being saved.
    begin
      @resource.save
      initial_state = @resource.aasm_state
      @resource.publish
      if @resource.valid?
        CurationTaskClient.send_curation(@resource.id, requested: curation_requested, remediation_requested: !curation_requested)
        curation_requested ? @resource.draft_curation_requested = true : @resource.accessibility_remediation_requested = true
      else
        @resource.update_column(column, false)
        @resource.aasm_state = initial_state
        raise InvalidResourceError
      end
    rescue CurationTaskClient::CurationError
      @resource.update_column(column, false)
      raise RequestError
    ensure
      @resource.aasm_state = initial_state
    end
  end
end
