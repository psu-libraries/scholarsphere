# frozen_string_literal: true

# https://github.com/shrinerb/shrine/blob/master/doc/testing.md#test-data
module ShrineTestData
  module_function

  def image_data
    attacher = Shrine::Attacher.new
    attacher.set(uploaded_image)

    # if you're processing derivatives
    # attacher.set_derivatives(
    #   large:  uploaded_image,
    #   medium: uploaded_image,
    #   small:  uploaded_image,
    # )

    JSON.parse(attacher.column_data)
  end

  def uploaded_image
    filename = 'image.png'
    path = Rails.root.join('spec', 'fixtures', filename)
    file = File.open(path, binmode: true)
    file_size = file.size

    # for performance we skip metadata extraction and assign test metadata
    uploaded_file = Shrine.upload(file, :store, metadata: false)
    uploaded_file.metadata.merge!(
      'size' => file_size,
      'mime_type' => 'image/png',
      'filename' => filename
    )

    uploaded_file
  end
end
