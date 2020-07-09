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
        proxy_id_isi: work.proxy_id
      )
  end

  private

    def permissions_schema
      PermissionsSchema.new(resource: work)
    end

    def work
      @work ||= resource.work
    end
end
