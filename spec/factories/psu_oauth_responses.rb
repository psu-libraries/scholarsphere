# frozen_string_literal: true

require Rails.root.join('spec', 'support', 'factory_bot_helpers')

FactoryBot.define do
  factory :psu_oauth_response, class: 'OmniAuth::AuthHash' do
    skip_create

    transient do
      sequence(:access_id, 500) { |n| FactoryBotHelpers.generate_access_id_from_name(given_name, surname, n) }
      given_name { Faker::Name.first_name }
      surname { Faker::Name.last_name }
      email { "#{access_id}@psu.edu" }

      # Group names cannot contain spaces (see #155)
      groups { Array.new(3) { "cn=up.libraries.#{Faker::Currency.code.downcase},dc=psu,dc=edu" } }
    end

    provider { 'psu' }
    uid { access_id }
    info do
      {
        uid: access_id,
        access_id: access_id,
        email: email,
        admin_area: 'University Libraries',
        given_name: given_name,
        surname: surname,
        primary_affiliation: 'STAFF',
        groups: groups
      }
    end
  end
end
