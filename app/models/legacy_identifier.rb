# frozen_string_literal: true

class LegacyIdentifier < ApplicationRecord
  belongs_to :resource, polymorphic: true

  def self.find_uuid(version:, old_id:)
    legacy_id = find_by(version: version, old_id: old_id)

    legacy_id&.resource&.uuid ||
      raise(ActiveRecord::RecordNotFound)
  end

  # @param [Collection,Work,WorkVersion,FileResource] resource
  # @param [String] noid
  # @note Creates a legacy identifier for a Scholarsphere 3 noid
  def self.create_noid(resource:, noid:)
    return if noid.nil?

    resource.legacy_identifiers.find_or_initialize_by(version: 3, old_id: noid)
  end
end
