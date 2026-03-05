# Validates that an interactor fails when required fields are missing.
# Pass the list of required fields as an argument.
#
# Expects the caller to define a subject that returns an interactor result,
# and a let for each required field.

RSpec.define_context :interactor_expect do |required_fields|
  required_fields.each do |field|
    context "when the field #{field} is not present" do
      let(field) { nil }

      it "fails" do
        context = subject
        expect(context).to be_a_failure
      end

      it "populates the breaches" do
        context = subject
        expect(context.breaches).to include(field)
      end
    end
  end
end
