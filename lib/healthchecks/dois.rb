# frozen_string_literal: true

require 'data_cite'

module HealthChecks
  class Dois < OkComputer::Check
    attr_reader :threshold

    def initialize(threshold = 0)
      @threshold = threshold.to_i
    end

    def check
      response = DataCite::Client
        .new
        .search(state: 'draft')
      num_found = response.dig('meta', 'total')

      mark_message("Found #{num_found} draft dois")
      mark_failure if num_found > threshold
    end
  end
end
