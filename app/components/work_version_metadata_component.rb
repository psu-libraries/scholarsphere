# frozen_string_literal: true

class WorkVersionMetadataComponent < ApplicationComponent
  attr_reader :work_version,
              :mini

  # A list of WorkVersion's attributes that you'd like rendered, in the order
  # that you want them to appear.
  ATTRIBUTES = [
    :title,
    :subtitle,
    :visibility_badge,
    :creators,
    :version_number,
    :keyword,
    :display_rights,
    :display_work_type,
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

  MINI_ATTRIBUTES = [
    :first_creators,
    :deposited_at,
    :visibility_badge
  ].freeze

  def initialize(work_version:, mini: false)
    @work_version = decorate(work_version)
    @mini = mini
  end

  private

    def decorate(work_ver)
      return work_ver if work_ver.is_a? WorkVersionDecorator

      WorkVersionDecorator.new(work_ver)
    end

    def attributes_list
      mini ? MINI_ATTRIBUTES : ATTRIBUTES
    end

    def attributes
      attributes_list
        .map do |attr|
          label = format_label(attr)
          value = format_value(attr: attr, value: work_version.send(attr))
          [attr, label, value]
        end
        .reject { |_attr, _label, val| val.blank? }
    end

    def format_label(attr)
      WorkVersion.human_attribute_name(attr)
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
      "work-version-#{attr.to_s.gsub('_', '-')}"
    end
end
