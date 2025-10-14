# frozen_string_literal: true

class ManualReviewForm
  include ActiveModel::Model

  attr_reader :resource, :user
  attr_writer :under_manual_review

  def initialize(resource:, params:)
    @resource = resource
    super(params)
  end

  def under_manual_review
    @under_manual_review || resource.under_manual_review
  end

  def save
    resource.under_manual_review = under_manual_review
    resource.save!
  end
end
