# frozen_string_literal: true

# At the moment, there is/was a bug in Rails that did not let you override the
# queue adapter. It's unclear whether that bug is solved or not, so in the mean
# time this test is here to ensure nothing breaks or needs to be updated when we
# upgrade to future releases of Rails.
#
# At the moment it appears all is well if you _do not_ include
# `ActiveJob::TestHelper`. If you do include that module, you can no longer set
# the queue_adapter to inline (or more specifically, when you do, it will be
# overridden back to :test)

RSpec.configure do |config|
  config.around(:each, :inline_jobs) do |example|
    original_queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :inline
    example.run
    ActiveJob::Base.queue_adapter = original_queue_adapter
  end
end
