# frozen_string_literal: true

# @todo: this is a great candidate for refactoring with WorkVersionMetadataComponent

require 'action_view/component'

class CollectionMetadataComponent < ActionView::Component::Base
  attr_reader :collection

  validates :collection,
            presence: true

  # A list of Collection's attributes that you'd like rendered, in the order
  # that you want them to appear.
  ATTRIBUTES = [
    :title,
    :subtitle,
    :creator_aliases,
    :description,
    :keyword,
    :contributor,
    :publisher,
    :published_date,
    :subject,
    :language,
    :identifier,
    :based_near,
    :related_url,
    :source,
    :created_at
  ].freeze

  def initialize(collection:)
    @collection = collection
  end

  private

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
      elsif value.is_a? CollectionCreation
        value.alias
      else
        value.to_s
      end
    end

    def css_class(attr)
      "collection-#{attr.to_s.gsub('_', '-')}"
    end
end
