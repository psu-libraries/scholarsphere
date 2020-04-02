# frozen_string_literal: true

require 'penn_state/search_service'

module Qa
  module Authorities
    class Persons < Base
      attr_reader :term

      def search(term)
        @term = term

        persons.map do |person|
          formatted_response(person)
        end
      end

      private

        # @return Array<Creator, PennState::SearchService::Person>
        # @note if the same person is in both sources, prefer the Creator over the PennState::SearchService::Person
        def persons
          (creators + identities).reject do |person|
            person.is_a?(PennState::SearchService::Person) && creator_ids.include?(person.user_id)
          end
        end

        def creators
          @creators ||= Creator.where('surname ILIKE :q OR given_name ILIKE :q OR psu_id ILIKE :q', q: "%#{term}%")
        end

        # @note using Set enables faster searching for a given id instead of iterating over the entire array.
        def creator_ids
          @creator_ids ||= Set.new(creators.map(&:psu_id))
        end

        def identities
          @identities ||= PennState::SearchService::Client.new.search(text: term)
        end

        def formatted_response(result)
          case result
          when Creator
            formatted_creator(result)
          when PennState::SearchService::Person
            formatted_person(result)
          else
            raise NotImplementedError, "#{result.class} is not a valid person"
          end
        end

        def formatted_creator(result)
          {
            given_name: result.given_name,
            surname: result.surname,
            psu_id: result.psu_id,
            email: result.email,
            orcid: result.orcid,
            default_alias: result.default_alias,
            source: 'scholarsphere'
          }
        end

        def formatted_person(result)
          {
            given_name: result.given_name,
            surname: result.surname,
            psu_id: result.user_id,
            email: result.university_email,
            orcid: '',
            default_alias: result.display_name,
            source: 'penn state'
          }
        end
    end
  end
end
