# frozen_string_literal: true

require 'penn_state/search_service'

module Qa
  module Authorities
    class Persons < Base
      attr_reader :term

      def search(term)
        @term = term

        persons.map.with_index do |person, index|
          formatted_response(person)
            .merge(
              result_number: index + 1,
              total_results: persons.count
            )
        end
      end

      private

        # @return Array<Actor, PennState::SearchService::Person>
        # @note if the same person is in both sources, prefer the Actor over the PennState::SearchService::Person
        def persons
          (creators + identities).reject do |person|
            person.is_a?(PennState::SearchService::Person) && creator_ids.include?(person.user_id)
          end
        end

        def creators
          @creators ||= Actor
            .where('surname ILIKE :q OR given_name ILIKE :q OR psu_id ILIKE :q', q: "%#{term}%")
            .or(Actor.where(psu_id: identities.map(&:user_id)))
        end

        # @note using Set enables faster searching for a given id instead of iterating over the entire array.
        def creator_ids
          @creator_ids ||= Set.new(creators.map(&:psu_id))
        end

        def identities
          @identities ||= PennState::SearchService::Client.new.search(text: term)
        end

        def formatted_response(result)
          formatted = case result
                      when Actor
                        formatted_creator(result)
                      when PennState::SearchService::Person
                        formatted_person(result)
                      else
                        raise NotImplementedError, "#{result.class} is not a valid person"
                      end

          add_additional_metadata(formatted)
        end

        def formatted_creator(result)
          {
            given_name: result.given_name,
            surname: result.surname,
            psu_id: result.psu_id,
            email: result.email,
            orcid: result.orcid,
            default_alias: result.default_alias,
            actor_id: result.id,
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

        def add_additional_metadata(result)
          additional_metadata = nil

          if psu_id = result[:psu_id].presence
            label = Actor.human_attribute_name(:psu_id)
            value = psu_id
            additional_metadata = "#{label}: #{value}"
          elsif orcid = result[:orcid].presence
            label = Actor.human_attribute_name(:orcid)
            value = OrcidId.new(orcid).to_human
            additional_metadata = "#{label}: #{value}"
          end

          result.merge(additional_metadata: additional_metadata)
        end
    end
  end
end
