# Example: Using :interactor_expect for contract validation
#
# Tests that the interactor fails when any required field is nil,
# then tests the happy path separately.

require "rails_helper"

RSpec.describe CreateInvoice do
  subject do
    described_class.call(amount: amount, client: client, due_date: due_date)
  end

  let(:amount) { 100 }
  let(:client) { create(:client) }
  let(:due_date) { Date.tomorrow }

  in_context :interactor_expect, %i[amount client due_date]

  it "creates the invoice" do
    expect(subject).to be_success
    expect(subject.invoice).to be_persisted
  end
end
