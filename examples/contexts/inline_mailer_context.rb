# Delivers emails inline (synchronously) during tests.
# Clears the deliveries before and after each test.

RSpec.define_context :with_inline_mailer do
  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :inline
    ActionMailer::Base.deliveries.clear
    example.run
    ActionMailer::Base.deliveries.clear
    ActiveJob::Base.queue_adapter = original_adapter
  end

  execute_tests
end
