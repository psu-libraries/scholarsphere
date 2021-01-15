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
end
