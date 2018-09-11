# frozen_string_literal: true

# Not using in_context here because we want to be sure we are no hidding a bug.
module ContextTestHelper
  def test_inexisting_context(context_name, description = nil, namespace: nil, ns: nil)
    namespace ||= ns
    description ||= "using in_context defined in a another context"
    instance_exec do
      begin
        in_context context_name, ns: namespace
        # If we get there the test has failed T_T
        describe description do
          it "is well scoped" do
            expect(false).to be_truthy
          end
        end
      rescue RspecInContext::NoContextFound
        describe description do
          it "is well scoped" do
            expect(true).to be_truthy
          end
        end
      end
    end
  end
end
