# frozen_string_literal: true

# @abstract This is a single authority service that wraps three different types of sources: Scholarsphere Actor records,
# Penn State identity service records, and Orcid ids. The results of all three are combined into a uniform json output
# that can be used by the forms for adding creators to work versions and collections. This class can remove duplicate
# results from the different sources ensuring that Actor records are preferred over the other two.

require 'penn_state/search_service'
require 'orcid'

module Qa
  module Authorities
    class Persons < Base
      attr_reader :term

      def search(term)
        @term = term

        formatted_persons.map.with_index do |person, index|
          person.merge(
            result_number: index + 1,
            total_results: persons.count,
            additional_metadata: additional_metadata(person)
          )
        end
      end

      private

        # @note if the same person exists as a PennState::SearchService::Person and an Actor, prefer the Actor
        def persons
          (creators + identities + orcid).reject do |person|
            person.is_a?(PennState::SearchService::Person) && creator_ids.include?(person.user_id)
          end
        end

        def formatted_persons
          persons.map { |person| formatted_response(person) }
        end

        # @note Augments the fuzzy search with any additional results from the Penn State identity search. If the person
        # exists as an Actor in Scholarsphere, but wasn't picked up by the fuzzy search, the identity search would
        # return their record.
        def creators
          @creators ||= Actor
            .where('surname ILIKE :q OR given_name ILIKE :q OR psu_id ILIKE :q', q: "%#{term}%")
            .where('psu_id IS NOT NULL OR orcid IS NOT NULL')
            .or(Actor.where(psu_id: identities.map(&:user_id)))
        end

        # @note using Set enables faster searching for a given id instead of iterating over the entire array.
        def creator_ids
          @creator_ids ||= Set.new(creators.map(&:psu_id))
        end

        def identities
          @identities ||= PennState::SearchService::Client.new.search(text: term)
        end

        # @note If the person already exists in Scholarsphere with the given orcid, return the Actor record instead.
        # Because none of the other searches rely on orcid id, there is no concern for duplicate results.
        def orcid
          @orcid ||= begin
                       orcid = OrcidId.new(term)

                       return [] unless orcid.valid?

                       Array.wrap(Actor.find_by(orcid: orcid.to_s) || Orcid::Public::Person.new(orcid.to_human))
                     rescue Orcid::NotFound
                       []
                     end
        end

        def formatted_response(result)
          case result
          when Actor
            formatted_creator(result)
          when PennState::SearchService::Person
            formatted_person(result)
          when Orcid::Public::Person
            formatted_orcid(result)
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

        def formatted_orcid(result)
          {
            given_name: result.given_names,
            surname: result.family_name,
            email: result.emails.default,
            orcid: OrcidId.new(result.id).to_s,
            default_alias: result.credit_name,
            source: 'orcid'
          }
        end

        def additional_metadata(result)
          if result[:psu_id].presence
            I18n.t('dashboard.form.contributors.edit.psu_identity', id: result[:psu_id])
          elsif result[:orcid].presence
            I18n.t('dashboard.form.contributors.edit.orcid_identity', id: OrcidId.new(result[:orcid]).to_human)
          end
        end
    end
  end
end
