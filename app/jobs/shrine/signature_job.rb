# frozen_string_literal: true

class Shrine::SignatureJob < ApplicationJob
  Shrine.plugin :signature
  queue_as :signature

  def perform(file_resource_id:)
    file_resource = FileResource.find(file_resource_id)
    file_resource.with_lock do
      attacher = file_resource.file_attacher
      io = Shrine.uploaded_file(attacher.file_data)
      attacher.file.add_metadata(
        'sha256' => Shrine.signature(io, :sha256),
        'md5' => Shrine.signature(io, :md5)
      )
      attacher.write
      file_resource.save
    end
  end
end
