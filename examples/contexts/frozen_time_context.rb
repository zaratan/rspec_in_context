# Freezes time for the duration of the tests.
# Uses ActiveSupport's freeze_time.

RSpec.define_context :with_frozen_time do
  before { freeze_time }

  execute_tests
end
