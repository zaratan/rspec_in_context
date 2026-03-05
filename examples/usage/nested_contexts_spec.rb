# Example: Nesting multiple contexts together
#
# Combines :with_frozen_time and :with_inline_mailer
# to test time-sensitive email delivery.

require "rails_helper"

RSpec.describe PasswordReset do
  in_context :with_frozen_time do
    in_context :with_inline_mailer do
      it "sends the reset email" do
        user = create(:user)

        PasswordReset.call(user)

        expect(ActionMailer::Base.deliveries.size).to eq(1)
      end

      it "includes the current timestamp" do
        user = create(:user)

        PasswordReset.call(user)

        expect(ActionMailer::Base.deliveries.last.body.to_s)
          .to include(Time.current.iso8601)
      end
    end
  end
end
