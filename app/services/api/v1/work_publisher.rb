# frozen_string_literal: true

module Api
  module V1
    class WorkPublisher
      # @return [WorkPublisher]
      def self.call(*args)
        publisher = new(*args)
        publisher.call
        publisher
      end

      attr_reader :metadata, :depositor, :content, :permissions

      # @param [ActionController::Parameters] metadata
      # @param [String] depositor
      # @param [Array<ActionController::Parameters>] content
      # @param [ActionController::Parameters] permissions
      def initialize(metadata:, depositor_access_id:, content:, permissions: {})
        @metadata = metadata
        @depositor = BuildNewActor.call(psu_id: depositor_access_id)
        @content = content
        @permissions = permissions
      end

      # @return [Work]
      def call
        WorkVersion.transaction do
          UpdatePermissionsService.call(resource: work, permissions: permissions, create_agents: true)
          work_version = work.versions.first

          content.map do |file|
            work_version.file_resources.build(file: file[:file], deposited_at: file[:deposited_at])
          end

          work_version.publish
          work_version.save!
          work.reload
        end
      rescue ActiveRecord::RecordInvalid
        work
      end

      # @return [Work]
      def work
        @work ||= Work.build_with_empty_version(
          work_type: metadata.delete(:work_type),
          visibility: metadata.delete(:visibility),
          embargoed_until: metadata.delete(:embargoed_until),
          depositor: depositor,
          deposited_at: metadata.delete(:deposited_at),
          doi: metadata.delete(:doi),
          versions_attributes: [
            metadata.merge!('creators' => build_authorships)
          ]
        )
      end

      # @return [ActiveModel::Errors]
      def errors
        work.errors.merge!(_errors)
        work.errors
      end

      private

        def build_authorships
          metadata.fetch(:creators, []).each_with_index.map do |authorship_attributes, index|
            psu_id = authorship_attributes.delete('psu_id')
            orcid = authorship_attributes.delete('orcid')

            Authorship.new(
              authorship_attributes
                .merge(
                  actor: build_actor(psu_id: psu_id, orcid: orcid),
                  position: (index + 1) * 10
                )
            )
          end
        end

        def build_actor(psu_id:, orcid:)
          return if psu_id.nil? && orcid.nil?
          return depositor if psu_id == depositor.psu_id

          BuildNewActor.call(psu_id: psu_id, orcid: orcid)
        rescue PsuIdentity::SearchService::NotFound
          _errors.add(:psu_id, "access id #{psu_id} was not found at Penn State")
          nil
        rescue Orcid::NotFound
          _errors.add(:orcid, "id #{orcid} was not found in ORCiD")
          nil
        end

        def _errors
          @_errors ||= ActiveModel::Errors.new(self)
        end
    end
  end
end
