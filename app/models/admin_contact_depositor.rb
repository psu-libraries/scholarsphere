# frozen_string_literal: true

class AdminContactDepositor < MailForm::Base
  # Even though this won't ultimately send an email, still using
  # MailForm:Base to validate and create form
  attributes :send_to_name, validate: true
  attributes :send_to_email, validate: /\A[^@\s]+@[^@\s]+\z/i
  attributes :subject, validate: true
  attributes :cc_email_to, validate: true
  attributes :message, validate: true
end
