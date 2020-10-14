# frozen_string_literal: true

module Dashboard
  # @abstract Hijack the standard Blacklight::Solr::Response and return a set of database records for a given search
  # result from Solr.
  class PostgresResponse < Blacklight::Solr::Response
    def documents
      @documents ||= work_versions
    end
    alias_method :docs, :documents

    private

      def work_versions
        WorkVersion.where(uuid: work_version_uuids)
          .order(updated_at: :desc)
          .compact
          .map { |work_version| WorkVersionDecorator.new(work_version) }
      end

      def work_version_uuids
        response['docs'].map do |doc|
          doc['id'] if doc['model_ssi'] == 'WorkVersion'
        end
      end
  end
end
