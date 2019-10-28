# frozen_string_literal: true

require Rails.root.join('spec', 'support', 'factory_bot_helpers')

FactoryBot.define do
  factory :psu_oauth_response, class: 'OmniAuth::AuthHash' do
    skip_create

    transient do
      sequence(:access_id, 500) { |n| FactoryBotHelpers.generate_access_id_from_name("#{first_name} #{last_name}", n) }
      first_name { Faker::Name.first_name }
      last_name { Faker::Name.last_name }
      email { "#{access_id}@psu.edu" }
    end

    provider { 'psu' }
    uid { access_id }
    info do
      {
        uid: access_id,
        access_id: access_id,
        email: email,
        admin_area: 'University Libraries',
        first_name: first_name,
        last_name: last_name,
        primary_affiliation: 'STAFF',
        groups: ['some-group']
      }
    end
  end
end
