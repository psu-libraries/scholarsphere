# frozen_string_literal: true

# @todo: this is a great candidate for refactoring with WorkVersionMetadataComponent

class CollectionMetadataComponent < ApplicationComponent
  attr_reader :collection

  # A list of Collection's attributes that you'd like rendered, in the order
  # that you want them to appear.
  ATTRIBUTES = [
    :title,
    :subtitle,
    :creators,
    :keyword,
    :contributor,
    :publisher,
    :display_published_date,
    :subject,
    :language,
    :display_doi,
    :identifier,
    :based_near,
    :related_url,
    :source,
    :deposited_at
  ].freeze

  def initialize(collection:)
    @collection = decorate(collection)
  end

  private

    def decorate(col)
      return col if col.is_a? ResourceDecorator

      ResourceDecorator.new(col)
    end

    def attributes
      ATTRIBUTES
        .map do |attr|
          label = format_label(attr)
          value = format_value(collection.send(attr))
          [attr, label, value]
        end
        .reject { |_attr, _label, val| val.blank? || val.empty? }
    end

    def format_label(attr)
      Collection.human_attribute_name(attr)
    end

    def format_value(value)
      if value.is_a? Enumerable
        value
          .map { |member| format_value(member) }
          .compact
          .map { |member| %(<span class="multiple-member">#{member}</span>) }
          .join('; ')
          .html_safe
      elsif value.respond_to?(:strftime) # Date/Time/DateTime/TimeWithZone etc
        value.to_formatted_s(:long)
      elsif value.is_a? Authorship
        value.alias
      elsif value.is_a? ApplicationComponent
        render value
      else
        value.to_s
      end
    end

    def css_class(attr)
      "collection-#{attr.to_s.gsub('_', '-')}"
    end
end
