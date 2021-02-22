# frozen_string_literal: true

RSpec.configure do |config|
  config.before do |example|
    if example.metadata[:read_only]
      allow_any_instance_of(Scholarsphere::Application).to receive(:read_only?).and_return(true)
    end
  end
end
