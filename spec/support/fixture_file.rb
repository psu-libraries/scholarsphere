# frozen_string_literal: true

def fixture_file(filename)
  Pathname.new(RSpec.configuration.fixture_path).join(filename)
end

def text_file
  file = Tempfile.new(['', '.txt'])
  file.write(Faker::Lorem.paragraph)
  file.close
  Pathname.new(file)
end
