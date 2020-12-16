# frozen_string_literal: true

class FormErrorMessageComponent < ApplicationComponent
  attr_reader :form,
              :heading

  def initialize(form:, heading: nil)
    @form = form
    @heading = heading || default_heading
  end

  def render?
    errors.any?
  end

  def messages
    errors.full_messages
  end

  def errors
    form.object.errors
  end

  def default_heading
    I18n.t('dashboard.form.heading.error_message', error: pluralize(errors.count, 'error'))
  end
end
