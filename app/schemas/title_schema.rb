# frozen_string_literal: true

class TitleSchema < BaseSchema
  STOPWORDS = %w[
    a
    an
    the
  ].freeze

  def document
    return {} unless resource.respond_to?(:title)

    words = resource.title.downcase.gsub(/[^a-z0-9 ]/, '').split(' ')
    words.rotate!(1) if STOPWORDS.include?(words[0])

    {
      title_ssort: words.join(' ')
    }
  end
end
