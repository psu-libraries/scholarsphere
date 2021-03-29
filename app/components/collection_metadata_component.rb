# frozen_string_literal: true

# @todo: this is a great candidate for refactoring with WorkVersionMetadataComponent

class CollectionMetadataComponent < BaseMetadataComponent
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
    super(resource: collection)
  end

  private

    def decorate(col)
      return col if col.is_a? ResourceDecorator

      ResourceDecorator.new(col)
    end

    def attributes_list
      ATTRIBUTES
    end

    def format_label(attr)
      Collection.human_attribute_name(attr)
    end
end
