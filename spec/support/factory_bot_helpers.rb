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

  def self.generate_orcid
    Faker::Number.leading_zero_number(digits: 15) + ['X', *('0'..'9')].sample
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

  # @note Generate a random Noid-like string to mimic Scholarsphere 3's noid identifiers
  def self.noid
    [*('a'..'z'), *('0'..'9')].shuffle[0, 10].join
  end

  def self.valid_doi
    "doi:#{Doi::MANAGED_PREFIXES.sample}/#{Faker::Alphanumeric.alphanumeric(number: 8).insert(4, '-')}"
  end

  def self.invalid_doi
    "doi:#{Faker::Alphanumeric.alphanumeric(number: 8).insert(4, '-')}"
  end

  def self.unmanaged_doi
    "doi:10.#{Faker::Number.number(digits: 5)}/#{Faker::Alphanumeric.alphanumeric(number: 8).insert(4, '-')}"
  end

  def self.datacite_doi
    "#{Doi::MANAGED_PREFIXES.sample}/#{Faker::Alphanumeric.alphanumeric(number: 8).insert(4, '-')}"
  end
end
