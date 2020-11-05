# frozen_string_literal: true

class Incident < MailForm::Base
  ISSUE_TYPES = [
    'Depositing content',
    'Making changes to my content',
    'Browsing and searching',
    'Reporting a problem',
    'General inquiry or request'
  ].freeze

  attributes :name, validate: true
  attributes :email, validate: /\A[^@\s]+@[^@\s]+\z/i
  attributes :subject, validate: true
  attributes :message, validate: true
  attributes :category, validate: ISSUE_TYPES

  def headers
    {
      subject: "#{Rails.configuration.subject_prefix} #{subject}",
      to: Rails.configuration.incident_email,
      from: email
    }
  end
end
