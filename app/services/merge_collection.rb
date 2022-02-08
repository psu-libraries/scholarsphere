# frozen_string_literal: true

class MergeCollection
  class << self
    def call(uuid, delete_collection: true)
      instance = new(uuid, delete_collection)
      instance.save
      instance
    end
  end

  attr_reader :uuid,
              :delete_collection,
              :errors

  def initialize(uuid, delete_collection)
    @uuid = uuid
    @delete_collection = delete_collection
    @errors = []
    @successful = false # updated by #save
  end

  def save
    return false if collection.nil?
    return false unless valid?

    ActiveRecord::Base.transaction do
      PaperTrail.request(whodunnit: paper_trail_user) do
        new_work = merge_collection

        if !new_work.valid?
          new_work.errors.full_messages.each { |err| errors << err }
          return false
        end

        new_work.save!

        new_work.update_index
      end

      if delete_collection?
        collection.destroy!

        collection.works.each do |work|
          work.versions.each do |version|
            DestroyWorkVersion.call(version, force: true)
          end
        end
      end
    end

    @successful = true
    true
  end

  def delete_collection?
    @delete_collection
  end

  def valid?
    validate
    errors.empty?
  end

  def successful?
    @successful
  end

  def validate
    collection.works.each do |w|
      validate_work_metadata(w)
      validate_access_controls(w)
      validate_work_version_metadata(w)
      validate_creators(w)
    end
  end

  private

    def collection
      @collection ||= Collection.find_by(uuid: uuid)
    end

    def canonical_work
      @canonical_work ||= collection.works.first
    end

    def canonical_work_metadata
      @canonical_work_metadata ||= work_metadata(canonical_work)
    end

    def canonical_work_version
      @canonical_work_version ||= canonical_work.versions.first
    end

    def paper_trail_user
      @paper_trail_user ||= canonical_work_version.versions.first&.whodunnit
    end

    def validate_access_controls(work)
      %i[discover read edit].each do |level|
        %i[users groups].each do |agent|
          if canonical_work.send("#{level}_#{agent}").map(&:id) != work.send("#{level}_#{agent}").map(&:id)
            w_access = work.send("#{level}_#{agent}").inspect
            canonical_access = canonical_work.send("#{level}_#{agent}").inspect
            diff = "#{canonical_access}\n#{w_access}"

            errors << "Work-#{canonical_work.id} has different #{level} #{agent} than Work-#{work.id}\n#{diff}"
          end
        end
      end
    end

    def validate_creators(work)
      if canonical_work_version.creators.map(&:actor_id) != work.representative_version.creators.map(&:actor_id)
        w_creators = work.representative_version.creators.inspect
        canonical_creators = canonical_work_version.creators.inspect
        diff = "#{canonical_creators}\n#{w_creators}"

        errors << "Work-#{canonical_work.id} has different creators than Work-#{work.id}\n#{diff}"
      end
    end

    def validate_work_metadata(work)
      w_metadata = work_metadata(work)

      work_metadata_diff = MetadataDiff.call(
        OpenStruct.new(metadata: canonical_work_metadata),
        OpenStruct.new(metadata: w_metadata)
      )

      if w_metadata[:num_work_versions] != 1
        errors << "Work-#{work.id} has #{w_metadata[:num_work_versions]} work versions, but must only have 1"
      end

      if w_metadata[:num_files] != 1
        errors << "Work-#{work.id} has #{w_metadata[:num_files]} files, but must only have 1"
      end

      if work_metadata_diff.any?
        diff = work_metadata_diff.inspect
        errors << "Work-#{canonical_work.id} has different work metadata than Work-#{work.id}\n#{diff}"
      end

      if !work.representative_version.published?
        errors << "Work-#{canonical_work.id} is not published"
      end
    end

    def validate_work_version_metadata(work)
      work_version_metadata_diff = MetadataDiff.call(
        canonical_work_version,
        work.representative_version
      )

      attributes_we_dont_care_about = %i[title]
      work_version_metadata_diff = work_version_metadata_diff.reject do |k, _v|
        attributes_we_dont_care_about.include?(k.to_sym)
      end

      if work_version_metadata_diff.any?
        printable_diff = work_version_metadata_diff.inspect
        errors << "Work-#{canonical_work.id} has different WorkVersion metadata than Work-#{work.id}\n#{printable_diff}"
      end
    end

    def merge_collection
      deposited_at = collection
        .works
        .map(&:deposited_at)
        .compact
        .min

      all_file_resources = collection
        .works
        .map(&:representative_version)
        .map(&:file_resources)
        .flatten

      work = Work.build_with_empty_version(
        work_type: canonical_work.work_type,
        embargoed_until: canonical_work.embargoed_until,
        doi: canonical_work.doi,
        depositor: canonical_work.depositor,
        proxy_depositor: canonical_work.proxy_depositor,
        deposited_at: deposited_at,
        notify_editors: canonical_work.notify_editors
      )

      work.access_controls = canonical_work.access_controls.map(&:dup)

      version = work.versions.first
      version.metadata = canonical_work_version.metadata
      version.creators = canonical_work_version.creators.map(&:dup)
      version.file_resources = all_file_resources
      version.view_statistics = aggregate_view_statistics
      version.title = collection.title
      version.publish

      work
    end

    def work_metadata(work)
      {
        work_type: work.work_type,
        embargoed_until: work.embargoed_until,
        doi: work.doi,
        depositor_id: work.depositor&.id,
        proxy_depositor_id: work.proxy_depositor&.id,
        notify_editors: work.notify_editors,
        num_work_versions: work.versions.count,
        num_files: work.representative_version&.file_resources&.count
      }
    end

    def aggregate_view_statistics
      models_to_aggregate = [
        collection,
        collection.works.map(&:representative_version)
      ].flatten

      aggregated_stats = AggregateViewStatistics.call(models: models_to_aggregate)

      aggregated_stats.map do |date, count, _running_total|
        ViewStatistic.new(date: date, count: count)
      end
    end
end
