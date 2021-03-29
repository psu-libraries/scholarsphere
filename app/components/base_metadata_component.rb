# frozen_string_literal: true

class BaseMetadataComponent < ApplicationComponent
  attr_reader :resource

  def initialize(resource:)
    @resource = decorate(resource)
  end

  private

    def attributes_list
      raise NotImplementedError
    end

    def decorate(resource)
      raise NotImplementedError
    end

    def attributes
      attributes_list
        .map do |attr|
          label = format_label(attr)
          value = format_value(attr: attr, value: resource.send(attr))
          [attr, label, value]
        end
        .reject { |_attr, _label, val| val.blank? }
    end

    def format_label(attr)
      resource.to_model.class.human_attribute_name(attr)
    end

    def format_value(value:, attr:)
      if value.is_a? Enumerable
        format_multi_value(value: value, attr: attr)
      elsif value.respond_to?(:strftime) # Date/Time/DateTime/TimeWithZone etc
        value.to_formatted_s(:long)
      elsif value.is_a? Authorship
        value.display_name
      elsif value.is_a? ApplicationComponent
        render value
      elsif attr == :related_url
        format_link(value)
      else
        value.to_s
      end
    end

    def format_multi_value(value:, attr:)
      return nil if value.empty?

      list_items =
        value
          .map { |member| format_value(value: member, attr: attr) }
          .compact
          .map { |member| %(<li class="multiple-member">#{member}</li>) }
          .join

      %(<ol class="multiple-values">#{list_items}</ol>).html_safe
    end

    def format_link(text)
      text.gsub(
        URI::DEFAULT_PARSER.make_regexp,
        '<a href="\0" target="_blank">\0</a>'
      ).html_safe
    end

    def css_class(attr)
      [resource.model_name.param_key, attr]
        .join('-')
        .dasherize
    end
end
