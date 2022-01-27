# frozen_string_literal: true

# @abstract This duplicates Qa::Authorities::Persons with the only difference being only Penn State users are returned
# in a search. An alternative implementation would be to define this as a subauthority of Persons, but this just seems
# easier.
module Qa
  module Authorities
    class Users < Persons
      private

        # @return Array<PsuIdentity::SearchService::Person>
        def persons
          identities
        end
    end
  end
end
