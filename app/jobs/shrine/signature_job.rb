# frozen_string_literal: true

class Shrine::SignatureJob < ApplicationJob
  Shrine.plugin :signature
  queue_as :signature

  def perform(file_resource:)
    file_resource.with_lock do
      attacher = file_resource.file_attacher
      io = Shrine.uploaded_file(attacher.file_data)
      tmp = io.download
      attacher.file.add_metadata(
        'sha256' => Shrine.signature(tmp, :sha256),
        'md5' => Shrine.signature(tmp, :md5)
      )
      attacher.write
      file_resource.save
      tmp.delete
    end
  end
end
