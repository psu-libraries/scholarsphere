# frozen_string_literal: true

class MetadataFactory
  def work_version
    @work_version ||= full_metadata
  end

  private

    def full_metadata
      {
        title: Faker::Book.title,
        subtitle: fancy_title,
        keywords: Faker::Science.element,
        rights: Faker::Lorem.sentence,
        description: Faker::Lorem.paragraph,
        resource_type: Faker::House.furniture,
        contributor: Faker::Artist.name,
        publisher: Faker::Book.publisher,
        published_date: Faker::Date.between(from: 2.years.ago, to: Date.today).iso8601,
        subject: Faker::Book.genre,
        language: Faker::Nation.language,
        identifier: Faker::Number.leading_zero_number(digits: 10),
        based_near: fancy_geo_location,
        related_url: Faker::Internet.url,
        source: Faker::SlackEmoji.emoji
      }
    end

    def fancy_title
      "#{Faker::Lorem.words(number: rand(1..5)).join(' ').capitalize}: " \
        "\"#{Faker::Lorem.words.join(', ')}; #{Faker::Lorem.words.join("'s ")}\""
    end

    def fancy_geo_location
      "#{Faker::Address.city_prefix} #{Faker::Address.city_suffix}, #{Faker::Address.country}"
    end
end
