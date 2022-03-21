# frozen_string_literal: true

class CollectionWorkMembership < ApplicationRecord
  belongs_to :collection
  belongs_to :work

  # Always order these records based on their position. I know that using
  # default_scope is considered by some to be an antipattern, but in this
  # particular cause, adding this order to the association in the Collection
  # model produced undesirable and strange results. I find it very unlikely that
  # we'd want to order the works _not_ according to their explicitly defined
  # position, so I think this is a good solution in this case.
  default_scope -> { order(position: :asc) }

  validates :collection_id,
            uniqueness: {
              scope: :work_id
            }

  after_create :set_thumbnail_selection

  private

    def set_thumbnail_selection
      # The MembersController accepts_nested_attributes_for all WorKCollectionMembers before the Collection is saved
      # Therefore collection.works.blank? lets us know if the collection has just been created
      if collection.works.blank? && work.auto_generated_thumbnail_url.present?
        collection.update thumbnail_selection: ThumbnailSelections::AUTO_GENERATED
      end
    end
end
