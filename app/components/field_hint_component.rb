# frozen_string_literal: true

class FieldHintComponent < ApplicationComponent
  attr_reader :form,
              :attribute

  class << self
    def markdown
      @markdown ||= Redcarpet::Markdown.new(
        Redcarpet::Render::HTML.new(filter_html: false),
        {}
      )
    end
  end

  def initialize(form:, attribute:)
    @form = form
    @attribute = attribute
  end

  def render?
    I18n.exists?(i18n_key)
  end

  def dom_id
    return unless render?

    "#{form_field_id}-hint"
  end

  def hint_text
    render_markdown I18n.t(i18n_key)
  end

  def i18n_key
    @i18n_key ||= ['helpers', 'hint', form.object.class.model_name.i18n_key, attribute].join('.')
  end

  private

    def render_markdown(text)
      rendered = self.class.markdown.render(text)

      # remove the surrounding <p> tag that redcarpet insists on inserting
      rendered
        .strip
        .gsub(/\A<p>(.*)<\/p>\Z/m, '\1')
    end

    # @note Based off of ActionView::Helpers::Tags::Base#tag_id.
    def form_field_id
      sanitized_object_name = form.object_name
        .gsub(/\]\[|[^-a-zA-Z0-9:.]/, '_') # Replace non-alphanumerics with '_'
        .sub(/_$/, '')                     # Remove a trailing '_'
      [sanitized_object_name, attribute.to_s].join('_')
    end
end
