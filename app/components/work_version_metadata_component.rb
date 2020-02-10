# frozen_string_literal: true

require 'action_view/component'

class WorkVersionMetadataComponent < ActionView::Component::Base
  attr_reader :work_version

  validates :work_version,
            presence: true

  # A list of WorkVersion's attributes that you'd like rendered, in the order
  # that you want them to appear.
  ATTRIBUTES = [
    :title,
    :subtitle,
    :creator_aliases,
    :version_number,
    :description,
    :keywords,
    :rights,
    :resource_type,
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

  def initialize(work_version:)
    @work_version = work_version
  end

  private

    def attributes
      ATTRIBUTES
        .map do |attr|
          label = format_label(attr)
          value = format_value(work_version.send(attr))
          [attr, label, value]
        end
        .reject { |_attr, _label, val| val.blank? }
    end

    def format_label(attr)
      WorkVersion.human_attribute_name(attr)
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
      elsif value.is_a? WorkVersionCreation
        value.alias
      else
        value.to_s
      end
    end

    def css_class(attr)
      "work-version-#{attr.to_s.gsub('_', '-')}"
    end
end
