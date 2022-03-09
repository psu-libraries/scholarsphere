# frozen_string_literal: true

class ResourceDecorator < SimpleDelegator
  include ActionView::Helpers::SanitizeHelper

  # @returns an appropriately-decorated object. This is a factory method
  def self.decorate(resource)
    return WorkVersionDecorator.new(resource) if resource.is_a? WorkVersion
    return WorkDecorator.new(resource) if resource.is_a? Work
    return CollectionDecorator.new(resource) if resource.is_a? Collection

    raise ArgumentError, "I don't know how to decorate a #{resource.class.name}"
  end

  # Rails convention for "un-decorating" objects:
  # https://api.rubyonrails.org/v6.0.0/classes/ActiveModel/Conversion.html#method-i-to_model
  def to_model
    undecorated = __getobj__

    # It's possible to compose decorators on top of each other, so keep digging
    # down the stack unitl we are no longer getting SimpleDelegators.
    # Also define a max number of nesting so we don't get an infinite loop.
    100.times do
      break unless undecorated.respond_to?(:__getobj__)

      undecorated = undecorated.__getobj__
    end

    undecorated
  end

  def partial_name
    model_name.singular
  end

  def description_html
    return '' if combined_description.blank?

    @description_html ||= render_markdown(combined_description)
  end

  def description_plain_text
    strip_tags(description_html)
      .strip # Remove any leading or trailing whitspace
  end

  def display_work_type
    return unless respond_to?(:work_type)

    Work::Types.display(work_type)
  end

  def display_published_date
    return unless respond_to?(:published_date)

    EdtfDate.humanize(published_date)
  end

  def display_doi
    return if resource_with_doi.doi.blank?

    MintingStatusDoiComponent.new(resource: resource_with_doi)
  end

  def visibility_badge
    VisibilityBadgeComponent.new(work: self)
  end

  def first_creators
    if creators.length > 3
      creators.take(3) + ['&hellip;']
    else
      creators.take(3)
    end
  end

  private

    def combined_description
      [try(:description), try(:publisher_statement)]
        .compact
        .join("\r\r")
    end

    def render_markdown(str)
      markdown = Redcarpet::Markdown.new(
        Redcarpet::Render::HTML.new(
          with_toc_data: false,
          filter_html: true,
          no_styles: true,
          safe_links_only: true,
          prettify: false,
          no_images: true
        ),
        autolink: true,
        tables: false
      )
      markdown.render(str).html_safe
    rescue StandardError
      str
    end
end
