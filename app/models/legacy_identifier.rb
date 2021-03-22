# frozen_string_literal: true

class LegacyIdentifier < ApplicationRecord
  belongs_to :resource, polymorphic: true

  def self.find_uuid(version:, old_id:)
    legacy_id = find_by(version: version, old_id: old_id)

    legacy_id&.resource&.uuid ||
      raise(ActiveRecord::RecordNotFound)
  end
end
