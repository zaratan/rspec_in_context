# rspec_in_context — LLM Reference

## What is this gem?

`rspec_in_context` is a Ruby gem that provides `define_context` / `in_context` as a replacement for RSpec's `shared_examples` / `it_behaves_like`. The key advantage: contexts can accept blocks that get injected at a specific point via `execute_tests`, making them composable like methods. Contexts can also accept arguments, be namespaced, and nest within each other.

## Setup

**Gemfile:**
```ruby
gem 'rspec_in_context'
```

**spec_helper.rb (or rails_helper.rb):**
```ruby
require 'rspec_in_context'

RSpec.configure do |config|
  config.include RspecInContext
end
```

Requires Ruby >= 3.2.

## API Reference

### `RSpec.define_context(name, namespace: nil, ns: nil, silent: true, print_context: nil, &block)`

Define a global context (available in all spec files). Use outside any `describe`/`context` block.

```ruby
RSpec.define_context :with_frozen_time do
  before { freeze_time }
  execute_tests
end
```

### `define_context(name, namespace: nil, ns: nil, silent: true, print_context: nil, &block)`

Define a scoped context (available only within the enclosing `describe`/`context` block). Use inside a spec.

```ruby
RSpec.describe MyService do
  define_context :with_valid_params do
    let(:params) { { name: "test" } }
    execute_tests
  end

  in_context :with_valid_params do
    it "works" do
      expect(MyService.call(params)).to be_success
    end
  end
end
```

**Parameters:**
- `name` (String, Symbol) — required. The context identifier.
- `namespace:` / `ns:` (String, Symbol) — optional namespace to avoid name collisions.
- `silent:` (Boolean, default: `true`) — when `true`, wraps in anonymous context. When `false`, wraps in a named context visible in `--format doc`.
- `print_context:` (Boolean) — inverse of `silent`. `print_context: true` is equivalent to `silent: false`.
- `&block` — required. The context body.

### `in_context(name, *args, namespace: nil, ns: nil, &block)`

Use a previously defined context. The optional block is injected where `execute_tests` appears in the context definition.

```ruby
in_context :with_frozen_time do
  it "uses frozen time" do
    expect(Time.current).to eq(Time.current) # always true
  end
end

# With arguments (no block)
in_context :validates_field, :email
```

**Parameters:**
- `name` (String, Symbol) — the context to use.
- `*args` — positional arguments passed to the context block.
- `namespace:` / `ns:` — namespace to look in.
- `&block` — optional. Injected at `execute_tests`.

### `execute_tests` / `instantiate_context`

Placeholder inside a `define_context` block. Marks where the caller's block (from `in_context`) will be injected.

```ruby
RSpec.define_context :setup_env do
  let(:user) { create(:user) }
  before { sign_in user }

  execute_tests  # <-- caller's block runs here
end
```

These are aliases. `instanciate_context` also works but is deprecated (typo).

## Key Concepts

### Scoped vs Global contexts

- **Scoped**: `define_context` inside a `describe`/`context` — automatically removed when the block ends.
- **Global**: `RSpec.define_context` outside any describe — available everywhere, never cleaned up.

### Block injection (execute_tests)

The core feature. When you call `in_context :foo do ... end`, the block is stored and injected where `execute_tests` appears in the `:foo` definition. If `execute_tests` is absent and you pass a block, the block is silently ignored.

### Arguments

Context blocks can accept arguments via block parameters:

```ruby
RSpec.define_context :validates_field do |field_name|
  context "when #{field_name} is nil" do
    let(field_name) { nil }
    it { is_expected.not_to be_valid }
  end
end

in_context :validates_field, :email
```

### Namespacing

Prevents name collisions when different parts of your test suite define contexts with the same name:

```ruby
RSpec.define_context :valid_params, ns: :users do ... end
RSpec.define_context :valid_params, ns: :posts do ... end

in_context :valid_params, ns: :users do ... end
```

If the same name exists in multiple namespaces and you don't specify `ns:`, `AmbiguousContextName` is raised.

### Silent mode

- `silent: true` (default): `in_context` wraps in an anonymous `context {}` block — invisible in `--format doc`.
- `silent: false` or `print_context: true`: wraps in `context("context_name") {}` — visible in `--format doc`.

### Thread-local block stack for nesting

Nested `in_context` calls work correctly. The gem uses `Thread.current[:test_block_stack]` (a stack) to track which block should be injected at each nesting level.

## Common Patterns

### Pattern: Setup context (before/let + execute_tests)

The most common pattern. Set up state, then let the caller provide assertions.

```ruby
RSpec.define_context :as_admin do
  let(:current_user) { create(:user, role: :admin) }
  before { sign_in current_user }
  execute_tests
end

in_context :as_admin do
  it "can access admin panel" do
    get admin_path
    expect(response).to have_http_status(:ok)
  end
end
```

### Pattern: Parameterized context (arguments)

Pass data to customize the context behavior.

```ruby
RSpec.define_context :contract_validation do |required_fields|
  required_fields.each do |field|
    context "when #{field} is missing" do
      let(field) { nil }
      it("fails") { expect(subject).to be_a_failure }
    end
  end
end

in_context :contract_validation, %i[name email phone]
```

### Pattern: Built-in tests + execute_tests

Include both built-in tests and a placeholder for injected tests.

```ruby
RSpec.define_context :authenticated_request do
  let(:user) { create(:user) }
  before { sign_in user }

  context "without authentication" do
    before { sign_out user }
    it("returns 401") { expect(response).to have_http_status(:unauthorized) }
  end

  execute_tests  # caller's authenticated tests go here
end
```

### Pattern: Inline define + use

For contexts only needed in one spec file.

```ruby
RSpec.describe ReportGenerator do
  define_context :with_sample_data do
    let!(:records) { create_list(:record, 5) }
    execute_tests
  end

  in_context :with_sample_data do
    it "generates the report" do
      expect(ReportGenerator.call.rows.count).to eq(5)
    end
  end
end
```

### Pattern: Nested in_context in define_context

Compose higher-level contexts from smaller ones.

```ruby
RSpec.define_context :full_integration do
  in_context :with_frozen_time do
    in_context :as_admin do
      execute_tests
    end
  end
end
```

### Pattern: File organization (spec/contexts/*.rb)

```
spec/
  contexts/
    authenticated_request_context.rb
    frozen_time_context.rb
    contract_validation_context.rb
  spec_helper.rb  # requires all contexts
```

```ruby
# spec_helper.rb
Dir[File.join(__dir__, "contexts", "**", "*.rb")].each { |f| require f }
```

## Error Reference

### `RspecInContext::NoContextFound`

**Cause:** `in_context` references a name that doesn't exist or is out of scope.

**Fix:** Check spelling, ensure the context is defined globally or in an enclosing scope.

### `RspecInContext::AmbiguousContextName`

**Cause:** The same context name exists in multiple namespaces and no namespace was specified.

**Fix:** Add `ns: :your_namespace` to `in_context`.

### `RspecInContext::InvalidContextName`

**Cause:** `define_context` called with `nil` or `""`.

**Fix:** Provide a valid string or symbol name.

### `RspecInContext::MissingDefinitionBlock`

**Cause:** `define_context` called without a block.

**Fix:** Add a block: `define_context(:name) { ... }`.

## Anti-patterns / Gotchas

### Forgetting execute_tests when passing a block

```ruby
# BAD — the block passed to in_context is silently ignored
RSpec.define_context :setup do
  let(:user) { create(:user) }
  # missing execute_tests!
end

in_context :setup do
  it "never runs" do  # <-- this test is lost
    expect(user).to be_present
  end
end

# GOOD
RSpec.define_context :setup do
  let(:user) { create(:user) }
  execute_tests
end
```

### Ambiguous context names without namespace

```ruby
# BAD — raises AmbiguousContextName
RSpec.define_context :valid_params, ns: :users do ... end
RSpec.define_context :valid_params, ns: :posts do ... end
in_context :valid_params do ... end  # which one?

# GOOD
in_context :valid_params, ns: :users do ... end
```

### Using deprecated instanciate_context

```ruby
# DEPRECATED — emits warning
instanciate_context

# GOOD
execute_tests
# or
instantiate_context
```

## Real-World Examples

The `examples/` directory in the repository contains real-world usage patterns:

- `examples/contexts/` — Context definitions (authentication, interactor contracts, frozen time, job setup, mailer, composed contexts)
- `examples/usage/` — Spec files showing how to use those contexts in practice

See `examples/README.md` for the full list.

## Complete Example

Showing multiple features together:

```ruby
# spec/contexts/api_context.rb
RSpec.define_context :authenticated_api, silent: false do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{user.token}" } }

  context "without authentication" do
    let(:headers) { {} }

    it "returns 401" do
      send(http_method, endpoint, headers: headers)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  execute_tests
end

RSpec.define_context :validates_contract do |required_fields|
  required_fields.each do |field|
    context "when #{field} is missing" do
      let(field) { nil }
      it("returns 422") { expect(response).to have_http_status(:unprocessable_entity) }
    end
  end
end

# spec/requests/api/projects_spec.rb
RSpec.describe "API Projects", type: :request do
  let(:http_method) { :post }
  let(:endpoint) { api_projects_path }

  in_context :authenticated_api do
    let(:name) { "My Project" }
    let(:description) { "A great project" }

    before do
      post endpoint, params: { name: name, description: description }, headers: headers
    end

    in_context :validates_contract, %i[name]

    it "creates the project" do
      expect(response).to have_http_status(:created)
      expect(json_response["name"]).to eq("My Project")
    end
  end
end
```
