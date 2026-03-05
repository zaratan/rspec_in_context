# Sets up ActiveJob in test mode for the duration of the tests.
# Useful when you need to assert on enqueued/performed jobs.

RSpec.define_context :with_test_jobs do
  include ActiveJob::TestHelper

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = original_adapter
  end

  execute_tests
end
