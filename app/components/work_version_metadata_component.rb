# frozen_string_literal: true

class WorkVersionMetadataComponent < BaseMetadataComponent
  attr_reader :mini

  # A list of WorkVersion's attributes that you'd like rendered, in the order
  # that you want them to appear.
  ATTRIBUTES = [
    :title,
    :subtitle,
    :visibility_badge,
    :creators,
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
    super(resource: work_version)
    @mini = mini
  end

  private

    def decorate(work_ver)
      return work_ver if work_ver.respond_to?(:display_rights)

      WorkVersionDecorator.new(work_ver)
    end

    def attributes_list
      mini ? MINI_ATTRIBUTES : ATTRIBUTES
    end

    def format_label(attr)
      WorkVersion.human_attribute_name(attr)
    end
end
