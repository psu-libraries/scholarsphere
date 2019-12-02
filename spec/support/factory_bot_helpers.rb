# frozen_string_literal: true

module FactoryBotHelpers
  def self.generate_access_id_from_name(given_name, surname, sequence_number)
    alphabet = ('a'..'z').to_a

    initials = [
      given_name || alphabet.sample,
      _middle_name = alphabet.sample,
      surname || alphabet.sample
    ].map(&:first).join('')

    format("#{initials}%<n>03d", n: sequence_number)
  end

  def self.fancy_geo_location
    "#{Faker::Address.city_prefix} #{Faker::Address.city_suffix}, #{Faker::Address.country}"
  end

  def self.work_title(count = 1)
    a = Faker::Lorem.words(number: rand(1..5)).join(' ').capitalize
    b = Faker::Lorem.words.join(', ')
    c = Faker::Lorem.words.join("'s ")
    id = count.ordinalize

    %(#{a}: "#{b}; #{id} #{c}")
  end
end
