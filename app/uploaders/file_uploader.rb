# frozen_string_literal: true

class FileUploader < Shrine
  plugin :backgrounding

  Attacher.promote_block do
    Shrine::PromotionJob.perform_later(
      record: record,
      name: name.to_s,
      file_data: file_data
    )
  end

  Attacher.destroy_block do
    Shrine::DestructionJob.perform_later(
      data: data
    )
  end
end
