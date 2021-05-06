# frozen_string_literal: true

module GeneratedUuids
  extend ActiveSupport::Concern

  # @note Postgres mints uuids, but they are not present until the record is reloaded from the database. For models that
  # have uuids, they should never be nil, so reloading them from the database will fix the issue.
  def uuid
    reload if persisted? && super.nil?

    super
  end
end
