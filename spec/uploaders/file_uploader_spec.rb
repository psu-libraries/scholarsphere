# frozen_string_literal: true

require 'rails_helper'
require 'shrine/storage/memory'

RSpec.describe FileUploader do
  describe 'oversize metadata' do
    around do |example|
      original_store = described_class.storages[:store]
      described_class.storages[:store] = Shrine::Storage::Memory.new
      example.run
    ensure
      described_class.storages[:store] = original_store
    end

    it 'sets oversize to false when image dimensions are readable' do
      image = instance_double(MiniMagick::Image, width: 1200, height: 900)
      allow(MiniMagick::Image).to receive(:open).and_return(image)

      metadata = upload_image.metadata

      expect(metadata['oversize']).to be(false)
    end

    it 'sets oversize to true when ImageMagick reports width or height exceeds limit' do
      error_message = <<~ERROR
        `identify -format %m %w %h %b /tmp/mini_magick20261109-1-w9tsqn.psb[0]` failed with status: 1 and error:
        identify-im6.q16: width or height exceeds limit `/tmp/mini_magick20261109-1-w9tsqn.psb' @ error/cache.c/OpenPixelCache/3928.
      ERROR
      allow(MiniMagick::Image).to receive(:open).and_raise(MiniMagick::Error.new(error_message))

      metadata = upload_image.metadata

      expect(metadata['oversize']).to be(true)
    end

    it 're-raises MiniMagick errors that are not width/height limit failures' do
      allow(MiniMagick::Image).to receive(:open).and_raise(MiniMagick::Error.new('identify failed: file format error'))

      expect { upload_image }.to raise_error(MiniMagick::Error)
    end

    def upload_image
      path = FileHelpers.fixture_file('image.png')

      File.open(path, binmode: true) do |file|
        FileUploader.upload(file, :store)
      end
    end
  end
end
