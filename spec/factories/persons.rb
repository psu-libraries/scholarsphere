# frozen_string_literal: true

require Rails.root.join('spec', 'support', 'factory_bot_helpers')

FactoryBot.define do
  factory :person, class: 'PennState::SearchService::Person' do
    skip_create

    transient do
      sequence(:access_id, 500) { |n| FactoryBotHelpers.generate_access_id_from_name(given_name, surname, n) }
      given_name { Faker::Name.first_name }
      surname { Faker::Name.last_name }
      email { "#{access_id}@psu.edu" }
    end

    data do
      {
        'userid' => access_id,
        'givenName' => given_name,
        'familyName' => surname,
        'universityEmail' => email,
        'affiliation' => ['STAFF'],
        'active' => 'true'
      }
    end

    initialize_with { new(data) }
  end
end
