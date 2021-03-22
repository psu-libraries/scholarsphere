# frozen_string_literal: true

class WorkVersionSchema < BaseSchema
  def document
    DefaultSchema.new(resource: resource)
      .document
      .merge(permissions_schema.document)
      .merge(
        latest_version_bsi: resource.latest_version?,
        embargoed_until_dtsi: work.embargoed_until,
        depositor_id_isi: work.depositor.id,
        proxy_id_isi: work.proxy_id,
        migration_errors_sim: migration_errors,
        deposited_at_dtsi: resource.deposited_at
      )
  end

  private

    def permissions_schema
      PermissionsSchema.new(resource: work)
    end

    def work
      @work ||= resource.work
    end

    # @note Remove duplicate errors that come from the parent work.
    def migration_errors
      errors = build_migration_errors
      errors
        .map { |error, _value| errors.delete(error) if error.match?(/^work/) }
      errors.full_messages
    end

    def build_migration_errors
      current_state = resource.aasm_state
      resource.publish unless resource.published?
      resource.validate
      resource.aasm_state = current_state
      resource.errors
    end
end
