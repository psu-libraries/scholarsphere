# frozen_string_literal: true

class AdminContactDepositor
  include ActiveModel::Model
  attr_accessor :send_to_name, :send_to_email, :subject

  validates :send_to_name, presence: true
  validates :send_to_email, format: /\A[^@\s]+@[^@\s]+\z/i
  validates :subject, presence: true
end
