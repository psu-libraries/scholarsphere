# frozen_string_literal: true

class Shrine::ThumbnailJob < ApplicationJob
  queue_as :thumbnails

  def perform(record)
    record.with_lock do
      attacher = record.file_attacher
      attacher.create_derivatives :thumbnail
      record.save
    end

    if record.thumbnail_upload.present?
      # If the created record is a thumbnail uploaded by a user,
      # then the associated resource needs to be reindexed
      record.thumbnail_upload.resource.update_index
    else
      # Update WorkVersions' solr docs with thumbnail url when
      # thumbnail is auto-generated from a WorkVersion upload
      record.work_versions.each(&:update_index)
    end
  rescue Shrine::AttachmentChanged, ActiveRecord::RecordNotFound
    # attachment has changed or record has been deleted, nothing to do
  end
end
