# frozen_string_literal: true

def fixture_file(filename)
  Pathname.new(RSpec.configuration.fixture_path).join(filename)
end
