# frozen_string_literal: true

class DepositorForm
  include ActiveModel::Model

  attr_reader :resource

  def initialize(resource:, params:)
    @resource = resource
    super(params)
  end

  def psu_id
    @psu_id ||= resource.depositor.psu_id
  end

  def psu_id=(psu_id)
    @psu_id = psu_id
  end

  def save
    resource.depositor = find_or_build_actor
    return false if errors.present?

    resource.save
  end

  private

    def find_or_build_actor
      Actor.find_by(psu_id: @psu_id) || BuildNewActor.call(psu_id: @psu_id)
    rescue PennState::SearchService::NotFound
      errors.add(:psu_id, :not_found, psu_id: @psu_id)
      resource.depositor
    end
end
