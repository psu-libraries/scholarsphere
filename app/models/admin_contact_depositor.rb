# frozen_string_literal: true

class AdminContactDepositor
  include ActiveModel::Model
  attr_accessor :send_to_name, :send_to_email, :subject, :cc_email_to, :message

  validates :send_to_name, presence: true
  validates :send_to_email, format: /\A[^@\s]+@[^@\s]+\z/i
  validates :subject, presence: true
  validate :validate_cc_email_to
  validates :message, presence: true

  def validate_cc_email_to
    if !cc_email_to.is_a?(Array) || cc_email_to.any?{ |e| !e.match(/\A[^@\s]+@[^@\s]+\z/i) }
      errors.add(:cc_email_to, :invalid)
    end
  end
end
