# frozen_string_literal: true

FactoryBot.define do
  factory :thumbnail_upload do
    resource factory: %i[work], has_draft: false
    file_resource { create(:file_resource) }

    factory :collection_thumbnail_upload do
      resource factory: %i[collection]
    end
  end
end
