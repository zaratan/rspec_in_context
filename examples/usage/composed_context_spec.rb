# Example: Using a composed context
#
# :service_processor reuses :interactor_expect internally,
# so you get contract validation + success test in one call.

require "rails_helper"

RSpec.describe DailyStatsProcessor do
  subject { described_class.call(account: account, date: date) }

  let(:account) { create(:account) }
  let(:date) { Date.current }

  in_context :service_processor
end
