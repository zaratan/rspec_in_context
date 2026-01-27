# TODO — Architectural Review

Issues identified during an exhaustive critical review of the codebase.

## CRITICAL

### 1. Add a Mutex around @contexts

The `@contexts` registry is a shared mutable global state with no synchronization. `add_context`, `remove_context`, `find_context` all read and write without a mutex. With `parallel_tests` in thread mode, this is a guaranteed race condition.

**Solution**: Add a `Mutex` around all operations on `@contexts`, or use `Concurrent::Map`.

**File**: `lib/rspec_in_context/in_context.rb`

### 2. Secure access to hooks.instance_variable_get(:@owner)

Accessing a private RSpec internal instance variable. If it disappears in a future version, `owner` will be `nil` and scoped contexts will never be cleaned up (silently).

**Solution**: Add a smoke test verifying `@owner` is not nil. Investigate whether `self` or `self.class` could serve as a substitute.

**File**: `lib/rspec_in_context/in_context.rb:191`

### 3. Secure the prepend on RSpec::Core::ExampleGroup.subclass

The `subclass(parent, description, args, registration_collection, &)` signature mirrors RSpec's internal implementation. The `"> 3.0"` version constraint is too loose for this level of coupling.

**Solution**: Restrict to `"~> 3.0"` and add a smoke test. Investigate whether a public RSpec hook (`after(:context)` or similar) could replace the prepend.

**Files**: `lib/rspec_in_context/context_management.rb`, `rspec_in_context.gemspec`

## MAJOR

### 4. Remove the ActiveSupport dependency

`require "active_support/all"` loads ALL of ActiveSupport for only:
- `HashWithIndifferentAccess`
- A single `present?` call (`namespace&.present?`)

`present?` → `namespace && !namespace.to_s.strip.empty?`
`HashWithIndifferentAccess` → plain Hash with `.to_s` on keys.

**Files**: `lib/rspec_in_context.rb`, `lib/rspec_in_context/in_context.rb`, `rspec_in_context.gemspec`

### 5. Fix typo instanciate_context → instantiate_context

Gallicism in the public API. The correct English word is `instantiate`.

**Solution**: Add `alias instantiate_context execute_tests` alongside the old one. Keep the old alias with a deprecation warning.

**File**: `lib/rspec_in_context/in_context.rb`

### 6. Improve tests to verify actual block execution

Many tests use `expect(true).to be_truthy` which does not verify the block was actually executed. If the block is not injected, the test is simply absent from the suite — no failure.

**Solution**: Use measurable side effects (counters, shared variables) to verify blocks are actually executed.

**Files**: `spec/rspec_in_context/in_context_spec.rb`, `spec/rspec_in_context/context_management_spec.rb`

### 7. Add clear_all_contexts! for memory cleanup

Global contexts (owner nil) are never freed. For long test suites with dynamically generated contexts, procs and their closures accumulate.

**Solution**: Add `RspecInContext::InContext.clear_all_contexts!` and optionally call it in `after(:suite)`.

**File**: `lib/rspec_in_context/in_context.rb`

### 8. Tighten dependency version constraints

`activesupport "> 2.0"` and `rspec "> 3.0"` have no upper bound. Use `"~>"` for main dependencies. Update rake to `"~> 13.0"`.

**File**: `rspec_in_context.gemspec`

## MINOR

### 9. Add a base exception class RspecInContext::Error

Cannot `rescue RspecInContext::Error` to catch all gem errors. Add `class Error < StandardError; end` and have `NoContextFound` and `AmbiguousContextName` inherit from it.

**File**: `lib/rspec_in_context/in_context.rb`

### 10. Remove useless instance_exec in define_context

The `instance_exec do ... end` wrapper in `define_context` (ClassMethods) does nothing since `hooks` is already accessible directly in the class context.

**File**: `lib/rspec_in_context/in_context.rb:188-196`

### 11. Remove faker from dependencies

`faker` is required in `spec_helper.rb` but never used in any test. Dead code.

**Files**: `spec/spec_helper.rb`, `rspec_in_context.gemspec`

## COSMETIC

### 12. Fix typos in code comments

- "find" → "found", "eventualy" → "eventually" (line 5 in_context.rb)
- "colisions" → "collisions" (namespace comment)

**File**: `lib/rspec_in_context/in_context.rb`
