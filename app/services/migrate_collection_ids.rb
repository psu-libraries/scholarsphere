# frozen_string_literal: true

class MigrateCollectionIds
  attr_reader :collection_uuid,
              :work_uuid,
              :version

  def self.call(collection_uuid, work_uuid)
    instance = new(collection_uuid, work_uuid)
    instance.migrate
    instance
  end

  def initialize(collection_uuid, work_uuid)
    @collection_uuid = collection_uuid
    @work_uuid = work_uuid
    @version = work&.latest_version
    @successful = false # updated by #migrate
  end

  def migrate
    return false if collection.nil? || work.nil?

    original_work_uuid = work.uuid
    work.doi = collection.doi
    work.uuid = collection.uuid
    legacy_ids = collection.legacy_identifiers.map(&:dup)
    view_statistics_attrs = aggregate_view_statistics

    ActiveRecord::Base.transaction do
      delete_result = DeleteCollection.call(collection.uuid)

      if delete_result.successful?
        migrate_legacy_identifiers(legacy_ids)
        migrate_view_statistics(view_statistics_attrs)
        work.save!
        work.update_index
        IndexingService.delete_document(original_work_uuid, commit: true)
      end
    end

    @successful = true
    true
  end

  def successful?
    @successful
  end

  private

    def collection
      return @collection if defined?(@collection)

      @collection = Collection.find_by(uuid: collection_uuid)
    end

    def work
      return @work if defined?(@work)

      @work = Work.find_by(uuid: work_uuid)
    end

    def migrate_legacy_identifiers(legacy_ids)
      legacy_ids.each do |legacy_id|
        legacy_id.resource = work
        legacy_id.save!
      end
    end

    def aggregate_view_statistics
      models_to_aggregate = [
        collection,
        collection.works.map(&:representative_version)
      ].flatten

      aggregated_stats = AggregateViewStatistics.call(models: models_to_aggregate)

      # Return an array of attributes for a bulk insert, rather than ActiveRecords, for speed
      aggregated_stats.map do |date, count, _running_total|
        {
          date: date,
          count: count,
          resource_type: version.class,
          resource_id: version.id,
          created_at: Time.zone.now,
          updated_at: Time.zone.now
        }
      end
    end

    def migrate_view_statistics(view_stats_attrs)
      return if view_stats_attrs.empty?

      ViewStatistic.insert_all!(view_stats_attrs)
    end
end
