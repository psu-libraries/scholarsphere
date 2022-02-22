# frozen_string_literal: true

class MigrateCollectionIds
  attr_reader :collection_uuid, :work_uuid

  def self.call(collection_uuid, work_uuid)
    instance = new(collection_uuid, work_uuid)
    instance.migrate
    instance
  end

  def initialize(collection_uuid, work_uuid)
    @collection_uuid = collection_uuid
    @work_uuid = work_uuid
    @successful = false # updated by #migrate
  end

  def migrate
    return false if collection.nil? || work.nil?

    original_work_uuid = work.uuid
    work.doi = collection.doi
    work.uuid = collection.uuid
    legacy_ids = collection.legacy_identifiers.map(&:dup)

    ActiveRecord::Base.transaction do
      delete_result = DeleteCollection.call(collection.uuid)

      if delete_result.successful?
        migrate_legacy_identifiers(legacy_ids)
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
      @collection ||= Collection.find_by(uuid: collection_uuid)
    end

    def work
      @work ||= Work.find_by(uuid: work_uuid)
    end

    def migrate_legacy_identifiers(legacy_ids)
      legacy_ids.each do |legacy_id|
        legacy_id.resource_type = 'Work'
        legacy_id.resource_id = work.id
        legacy_id.save!
      end
    end
end
