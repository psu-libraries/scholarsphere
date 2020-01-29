# frozen_string_literal: true

class Creator < ApplicationRecord
  # TODO validations? Indexes?
  has_many :work_version_creations,
           dependent: :restrict_with_exception

  has_many :work_versions,
           through: :work_version_creations
end
