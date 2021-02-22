# frozen_string_literal: true

module DataCite
  module Metadata
    class Collection < Base
      private

        def resource_type
          'Collection'
        end
    end
  end
end
