# frozen_string_literal: true

# Block Delivery Guard
# ====================
#
# This test infrastructure guards against two subtle failure modes specific
# to rspec_in_context where examples silently vanish from the suite.
#
# ## Problem 1: execute_tests is broken
#
# When using `in_context` with a block, that block is injected into the
# context definition via `execute_tests` / `instantiate_context`. If
# `execute_tests` is broken (e.g., thread-local stack corruption), the
# block is never evaluated. The `it` blocks inside are never registered
# with RSpec. The suite passes with fewer examples — no failure, no warning.
#
#   define_context "my context" do
#     execute_tests  # <- if this is a no-op, the block below is never injected
#   end
#
#   in_context "my context" do
#     it "silently vanishes" do ... end  # <- never registered
#   end
#
# Detection: we wrap each block passed to `in_context` in a proc that sets
# a closure flag `consumed = true` when it actually runs. After `in_context`
# returns (the definition phase is synchronous), we check the flag.
#
# ## Problem 2: in_context itself is broken
#
# If `in_context` fails to call `context { instance_exec(...) }`, even
# the `it` blocks defined directly inside the context definition vanish.
# This affects ALL in_context calls, not just those with blocks.
#
#   define_context "my context" do
#     it "also silently vanishes" do ... end
#   end
#
#   in_context "my context"  # <- if broken, the `it` above is never registered
#
# Detection: every `in_context` call must create at least one new child
# ExampleGroup (via `context {}`). We count children before and after the
# call. If no new group was created, `in_context` did not inject anything.
#
# ## Wiring (in spec_helper.rb)
#
#   RspecInContext::InContext::ClassMethods.prepend(InContextDeliveryCheck)
#
#   config.after(:suite) do
#     next if BlockDeliveryGuard.failures.empty?
#     # ... report and exit(1)
#   end
#
# ## Why this works
#
# - `in_context` evaluates its context block synchronously during the
#   definition phase (RSpec's `context {}` runs its block immediately to
#   collect `it`, `let`, `before`, etc.)
# - Inside that evaluation, `execute_tests` calls `instance_exec(&block)`
#   on the stack's top entry — which is our wrapped proc.
# - The closure captures the `consumed` flag in the wrapping method's scope,
#   so `instance_exec` (which changes `self`) does not affect it.
# - The children count check runs after `super` returns, when the definition
#   phase is complete.
#
# ## Problem 3 (bonus): in_context creates a group but with no examples
#
# If `in_context` creates a `context {}` but fails to inject the definition
# block (e.g., `instance_exec` is not called), the ExampleGroup exists but
# is empty. This is caught by checking that new child groups contain at
# least one descendant example.
#
# ## What it does NOT detect
#
# - Context definitions that produce fewer examples than expected. The guard
#   checks that at least one example exists, not completeness.
# - `in_context` calls whose context definition only contains `let`/`before`
#   without any `it` blocks will trigger a false positive for `:empty_group`.
#   In practice this doesn't happen in this test suite.

# Collects guard failure reports for the after(:suite) check.
module BlockDeliveryGuard
  @failures = []

  class << self
    attr_reader :failures
  end
end

# Prepended on RspecInContext::InContext::ClassMethods.
#
# Two checks per in_context call:
# 1. Did in_context create a new child ExampleGroup? (catches broken in_context)
# 2. If a block was passed, did execute_tests consume it? (catches broken execute_tests)
module InContextDeliveryCheck
  def in_context(context_name, *, namespace: nil, ns: nil, &block)
    children_before = children.size

    if block
      consumed = false
      wrapped_block =
        proc do |*blk_args|
          consumed = true
          instance_exec(*blk_args, &block)
        end
      super(context_name, *, namespace: namespace, ns: ns, &wrapped_block)

      unless consumed
        BlockDeliveryGuard.failures << {
          type: :block_not_consumed,
          context: context_name,
          location: caller_locations(1, 1).first.to_s,
        }
      end
    else
      super
    end

    new_children = children[children_before..]
    if new_children.empty?
      BlockDeliveryGuard.failures << {
        type: :no_group_created,
        context: context_name,
        location: caller_locations(1, 1).first.to_s,
      }
    elsif new_children.none? { |child| child.descendant_filtered_examples.any? }
      BlockDeliveryGuard.failures << {
        type: :empty_group,
        context: context_name,
        location: caller_locations(1, 1).first.to_s,
      }
    end
  end
end
