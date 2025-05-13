# frozen_string_literal: true

class AltTextForm
  include ActiveModel::Model

  attr_reader :file_version_membership

  def initialize(file_version_membership)
    @file_version_membership = file_version_membership
  end

  def alt_text
    @alt_text ||= file_version_membership.file_resource.file_data['metadata']['alt_text'] 
  end

  def alt_text=(alt_text)
    @alt_text = alt_text
  end

  def save
    file_version_membership.save
  end
end