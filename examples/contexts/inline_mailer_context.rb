# Delivers emails inline (synchronously) during tests.
# Clears the deliveries before and after each test.

RSpec.define_context :with_inline_mailer do
  around do |example|
    ActiveJob::Base.queue_adapter = :inline
    ActionMailer::Base.deliveries.clear
    example.run
    ActionMailer::Base.deliveries.clear
    ActiveJob::Base.queue_adapter = :test
  end

  execute_tests
end
