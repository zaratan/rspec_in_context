# Example of composing contexts together.
# This context reuses :interactor_expect and adds a success test.
#
# Shows how in_context can be used inside define_context
# to build higher-level reusable blocks.

RSpec.define_context :service_processor do
  in_context :interactor_expect, %i[account date]

  it "succeeds with valid params" do
    expect(subject).to be_success
  end
end
