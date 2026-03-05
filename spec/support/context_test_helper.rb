# frozen_string_literal: true

# Verifies that a context is no longer accessible (has been scoped out).
# Calls in_context at runtime (inside an `it` block) rather than at
# definition time. This is intentional: find_context is the first thing
# in_context does, so NoContextFound is raised regardless of call site.
module ContextTestHelper
  def test_inexisting_context(
    context_name,
    description = nil,
    namespace: nil,
    ns: nil
  )
    namespace ||= ns
    description ||= "context '#{context_name}' should not be accessible here"
    context_name_captured = context_name
    namespace_captured = namespace

    describe description do
      it "raises NoContextFound" do
        expect do
          # We need to call in_context at runtime, not at definition time
          self.class.in_context(context_name_captured, ns: namespace_captured)
        end.to raise_error(RspecInContext::NoContextFound)
      end
    end
  end
end
