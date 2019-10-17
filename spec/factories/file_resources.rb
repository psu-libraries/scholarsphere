# frozen_string_literal: true

FactoryBot.define do
  factory :file_resource do
    # Fast version with no image processing
    file_data { ShrineTestData.image_data }

    # Slow version with full image processing
    trait :with_processed_image do
      file_data { nil }
      file { Rack::Test::UploadedFile.new(fixture_file('image.png'), 'image/png') }
    end
  end
end
