# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:each, :sidekiq) do |example|
    original_queue_adapter = ActiveJob::Base.queue_adapter
    Sidekiq::Testing.disable!
    ActiveJob::Base.queue_adapter = :sidekiq
    example.run
    ActiveJob::Base.queue_adapter = original_queue_adapter
  end
end
