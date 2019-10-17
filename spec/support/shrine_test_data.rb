# frozen_string_literal: true

# https://github.com/shrinerb/shrine/blob/master/doc/testing.md#test-data
module ShrineTestData
  module_function

  def image_data(file_name)
    attacher = Shrine::Attacher.new
    attacher.set(uploaded_image(file_name))

    # if you're processing derivatives
    # attacher.set_derivatives(
    #   large:  uploaded_image,
    #   medium: uploaded_image,
    #   small:  uploaded_image,
    # )

    JSON.parse(attacher.column_data)
  end

  def uploaded_image(file_name)
    path = Rails.root.join('spec', 'fixtures', 'image.png')
    file = File.open(path, binmode: true)
    file_size = file.size

    # for performance we skip metadata extraction and assign test metadata
    uploaded_file = Shrine.upload(file, :store, metadata: false)
    uploaded_file.metadata.merge!(
      'size' => file_size,
      'mime_type' => 'image/png',
      'filename' => file_name
    )

    uploaded_file
  end
end
