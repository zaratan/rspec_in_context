# frozen_string_literal: true

require "securerandom"

RSpec.define_context "outside in_context" do
  it "works for outside context" do
    expect(true).to be_truthy
  end
end

RSpec.define_context "outside namespaced",
                     namespace: "outside",
                     silent: false do
  it "works" do
    expect(true).to be_truthy
  end
end

RSpec.define_context "outside short-namespaced", ns: "outside", silent: false do
  it "works" do
    expect(true).to be_truthy
  end
end

RSpec.define_context "silent outside in_context" do
  it "wraps in anonymous context by default" do
    expect(self.class.name).to match(/Anonymous/)
  end
end

RSpec.define_context "not silent outside in_context", silent: false do
  it "wraps in named context when silent: false" do
    # RSpec converts "not silent outside in_context" to "NotSilentOutsideInContext"
    expect(self.class.name).to match(/NotSilentOutsideInContext/)
  end
end

RSpec.define_context "print_context outside in_context", print_context: true do
  it "wraps in named context when print_context: true" do
    # RSpec converts "print_context outside in_context" to "PrintContextOutsideInContext"
    expect(self.class.name).to match(/PrintContextOutsideInContext/)
  end
end

describe RspecInContext::InContext do
  define_context "inside in_context" do
    it "works for inside context" do
      expect(true).to be_truthy
    end
  end

  define_context :with_symbol do
    it "works both with and without symbols" do
      expect(true).to be_truthy
    end
  end

  define_context "with test block" do
    it "doesn't find unexistant variable" do
      expect(defined?(new_var)).to be_falsy
    end

    context "with new variable" do
      let(:new_var) { true }

      execute_tests
    end
  end

  define_context "with instantiate block" do
    it "doesn't find unexistant variable" do
      expect(defined?(new_var)).to be_falsy
    end

    context "with variable instantiated" do
      instantiate_context

      it "works with another variable" do
        expect(another_var).to eq(:value)
      end
    end
  end

  define_context "with argument" do |name|
    it "doesn't find #{name}" do
      expect(defined?(outside_var)).to be_falsy
    end

    context "with #{name}" do
      let(name) { true }

      execute_tests
    end
  end

  define_context :nested do
    context "with inside_var defined" do
      let(:inside_var) { true }

      it "works in nested in_context" do
        expect(outside_var).to eq(inside_var)
      end
    end
  end

  define_context "in_context in in_context" do
    in_context "with argument", :inside do
      it "works to use a in_context inside a define_context" do
        expect(inside).to be_truthy
      end
    end
  end

  describe "overriding an existing context" do
    it "warns when redefining a context" do
      unique_name = "context_override_test_#{SecureRandom.hex(8)}"
      warnings = []
      allow(RspecInContext::InContext).to receive(:warn) { |msg|
        warnings << msg
      }

      # First definition - no warning expected
      RSpec.define_context(unique_name) {}
      expect(warnings).to be_empty

      # Second definition - should warn
      RSpec.define_context(unique_name) {}
      expect(warnings.size).to eq(1)
      expect(warnings.first).to match(
        /Overriding an existing context: #{unique_name}/,
      )
    ensure
      RspecInContext::InContext.contexts["global_context"]&.delete(unique_name)
    end
  end

  describe "input validation" do
    it "raises InvalidContextName when context_name is nil" do
      expect { RSpec.define_context(nil) {} }.to raise_error(
        RspecInContext::InvalidContextName,
        /cannot be nil or empty/,
      )
    end

    it "raises InvalidContextName when context_name is empty string" do
      expect { RSpec.define_context("") {} }.to raise_error(
        RspecInContext::InvalidContextName,
        /cannot be nil or empty/,
      )
    end

    it "raises MissingDefinitionBlock when no block is provided" do
      expect { RSpec.define_context("no_block_context") }.to raise_error(
        RspecInContext::MissingDefinitionBlock,
        /requires a block/,
      )
    end

    it "raises AmbiguousContextName when same name exists in multiple namespaces" do
      unique_name = "ambiguous_context_#{SecureRandom.hex(8)}"
      ns_a = :"namespace_a_#{SecureRandom.hex(4)}"
      ns_b = :"namespace_b_#{SecureRandom.hex(4)}"
      RSpec.define_context(unique_name, ns: ns_a) do
        it("works") { expect(true).to be_truthy }
      end
      RSpec.define_context(unique_name, ns: ns_b) do
        it("works") { expect(true).to be_truthy }
      end

      expect {
        RspecInContext::InContext.find_context(unique_name)
      }.to raise_error(
        RspecInContext::AmbiguousContextName,
        /exists in multiple namespaces/,
      )
    ensure
      RspecInContext::InContext.contexts[ns_a.to_s]&.delete(unique_name)
      RspecInContext::InContext.contexts[ns_b.to_s]&.delete(unique_name)
    end
  end

  describe "edge cases" do
    define_context "context with execute_tests but no block" do
      let(:defined_in_context) { :context_value }

      execute_tests

      it "does not fail when execute_tests is called without a block" do
        expect(defined_in_context).to eq(:context_value)
      end
    end

    in_context "context with execute_tests but no block"

    define_context "context with multiple arguments" do |arg1, arg2, arg3|
      it "receives all arguments: #{arg1}, #{arg2}, #{arg3}" do
        expect(arg1).to eq(:first)
        expect(arg2).to eq(:second)
        expect(arg3).to eq(:third)
      end
    end

    in_context "context with multiple arguments", :first, :second, :third

    define_context :context_defined_with_symbol do
      let(:symbol_proof) { :from_symbol_context }

      it "is reachable when defined with symbol" do
        expect(symbol_proof).to eq(:from_symbol_context)
      end
    end

    in_context :context_defined_with_symbol
    in_context "context_defined_with_symbol" # Also works with string
  end

  describe "deprecated instanciate_context" do
    define_context "deprecation test" do
      execute_tests
    end

    it "emits a deprecation warning" do
      expect { self.class.instanciate_context }.to output(
        /DEPRECATION.*instanciate_context.*deprecated/,
      ).to_stderr
    end
  end

  describe "in_context calls" do
    in_context "outside in_context"
    in_context "inside in_context"
    in_context "with_symbol"

    in_context "with test block" do
      it "works with new_var" do
        expect(new_var).to be_truthy
      end
    end

    in_context "with instantiate block" do
      let(:another_var) { :value }
    end

    in_context "with argument", :outside_var do
      it "works with outside_var" do
        expect(outside_var).to be_truthy
      end

      in_context :nested
    end

    in_context "in_context in in_context"
  end

  describe "nested in_context with blocks" do
    define_context "outer with execute" do
      context "outer layer" do
        let(:outer_var) { :outer_value }

        execute_tests
      end
    end

    define_context "middle with execute" do
      context "middle layer" do
        let(:middle_var) { :middle_value }

        execute_tests
      end
    end

    define_context "inner with execute" do
      context "inner layer" do
        let(:inner_var) { :inner_value }

        execute_tests
      end
    end

    describe "two levels of nesting with blocks" do
      in_context "outer with execute" do
        it "has access to outer_var from outer block" do
          expect(outer_var).to eq(:outer_value)
        end

        in_context "inner with execute" do
          it "has access to both outer_var and inner_var" do
            expect(outer_var).to eq(:outer_value)
            expect(inner_var).to eq(:inner_value)
          end
        end

        it "still has access to outer_var after inner context" do
          expect(outer_var).to eq(:outer_value)
        end
      end
    end

    # This test proves the stack is necessary: a define_context that calls
    # in_context (which pushes/pops) and then execute_tests (which needs
    # the *outer* block). Without a stack, the inner in_context would
    # clobber the outer block and execute_tests would get nil.
    define_context "context with in_context then execute_tests" do
      in_context "inner with execute" do
        it "inner block was injected" do
          expect(inner_var).to eq(:inner_value)
        end
      end

      context "after inner in_context" do
        execute_tests
      end
    end

    describe "stack correctness: in_context before execute_tests in same define_context" do
      in_context "context with in_context then execute_tests" do
        # This let is injected via execute_tests above.
        # If the stack is broken, execute_tests gets nil and this it block
        # is never registered — the global example count guard catches that.
        let(:proof_of_injection) { :injected }

        it "outer block was actually injected by execute_tests" do
          expect(proof_of_injection).to eq(:injected)
        end
      end
    end

    describe "three levels of nesting with blocks" do
      in_context "outer with execute" do
        in_context "middle with execute" do
          in_context "inner with execute" do
            it "has access to all three variables" do
              expect(outer_var).to eq(:outer_value)
              expect(middle_var).to eq(:middle_value)
              expect(inner_var).to eq(:inner_value)
            end
          end

          it "has access to outer and middle but not inner" do
            expect(outer_var).to eq(:outer_value)
            expect(middle_var).to eq(:middle_value)
            expect(defined?(inner_var)).to be_falsy
          end
        end

        it "has access to outer only" do
          expect(outer_var).to eq(:outer_value)
          expect(defined?(middle_var)).to be_falsy
        end
      end
    end
  end

  describe "silent and print_context options" do
    define_context "silent context" do
      it "wraps in anonymous context by default" do
        expect(self.class.name).to match(/Anonymous/)
      end
    end

    define_context "not silent context", silent: false do
      it "wraps in named context when silent: false" do
        # RSpec converts "not silent context" to "NotSilentContext"
        expect(self.class.name).to match(/NotSilentContext/)
      end
    end

    define_context "print_context context", print_context: true do
      it "wraps in named context when print_context: true" do
        # RSpec converts "print_context context" to "PrintContextContext"
        expect(self.class.name).to match(/PrintContextContext/)
      end
    end

    in_context "silent context"
    in_context "not silent context"
    in_context "print_context context"
    in_context "silent outside in_context"
    in_context "not silent outside in_context"
    in_context "print_context outside in_context"
  end

  describe "namespacing" do
    in_context "outside namespaced"
    in_context "outside namespaced", namespace: :outside
    in_context "outside namespaced", ns: "outside"
    in_context "outside short-namespaced", ns: :outside
    test_inexisting_context "outside namespaced", namespace: :not_exist

    define_context "inside namespaced", namespace: :inside, silent: false do
      it "works" do
        expect(true).to be_truthy
      end
    end

    define_context :inside, ns: :inside, silent: false do
      it "works" do
        expect(true).to be_truthy
      end
    end

    define_context "inside namespaced in inside2",
                   ns: :inside2,
                   silent: false do
      it "works" do
        expect(true).to be_truthy
      end
    end

    # When only one namespace has the context, it can be found without specifying namespace
    in_context "inside namespaced"
    in_context "inside namespaced", namespace: :inside
    in_context :inside, ns: :inside
    in_context "inside namespaced", ns: :inside
    in_context "inside namespaced in inside2", ns: :inside2
    test_inexisting_context "inside namespaced", namespace: :not_exist
    describe "context isolation still work" do
      define_context "isolated namespaced", ns: :isolated, silent: false do
        it "works" do
          expect(true).to be_truthy
        end
      end
      in_context "isolated namespaced", ns: :isolated
      in_context :inside, ns: :inside
    end
    test_inexisting_context "isolated namespaced"
    test_inexisting_context "isolated namespaced", ns: :isolated
  end

  describe "clear_all_contexts!" do
    it "removes all stored contexts and allows re-creation" do
      # Save current state (preserve the default block by copying into a new Hash with the same default)
      original = RspecInContext::InContext.contexts
      saved = Hash.new { |hash, key| hash[key.to_s] = {} }
      original.each { |k, v| saved[k] = v.dup }

      unique_name = "clearable_#{SecureRandom.hex(8)}"
      RSpec.define_context(unique_name) do
        it("works") { expect(true).to be_truthy }
      end

      expect(RspecInContext::InContext.find_context(unique_name)).not_to be_nil

      RspecInContext::InContext.clear_all_contexts!

      # After clear, the context should no longer exist
      expect do
        RspecInContext::InContext.find_context(unique_name)
      end.to raise_error(RspecInContext::NoContextFound)

      # contexts should return a fresh empty hash
      expect(RspecInContext::InContext.contexts).to be_empty
    ensure
      # Restore previous state so other tests aren't affected
      RspecInContext::InContext.instance_variable_set(:@contexts, saved)
    end
  end

  describe "RSpec internals smoke tests" do
    # These tests verify that private RSpec APIs we depend on still exist.
    # If they break, context scoping will silently stop working.

    # hooks is only available at describe level, capture it here
    hooks_owner = hooks.instance_variable_get(:@owner)

    it "hooks exposes @owner for context scoping" do
      expect(hooks_owner).not_to be_nil
      expect(hooks_owner).to be_a(Class)
    end

    it "ExampleGroup.subclass is prepended with ContextManagement" do
      ancestors = RSpec::Core::ExampleGroup.singleton_class.ancestors
      expect(ancestors).to include(RspecInContext::ContextManagement)
    end
  end
end
