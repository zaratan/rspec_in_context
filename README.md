# RspecInContext

[![Gem Version](https://badge.fury.io/rb/rspec_in_context.svg)](https://badge.fury.io/rb/rspec_in_context)
![Test and Release badge](https://github.com/zaratan/rspec_in_context/workflows/Test%20and%20Release/badge.svg)

This gem is here to help you write better shared_examples in RSpec.

Ever been bothered by the fact that they don't really behave like methods and that you can't pass them a block? There you go: `rspec_in_context`

## Why not just shared_examples?

`shared_examples` are great but they have a few limitations that can get annoying:

**You can't inject a block of tests at a specific point.** With `shared_examples`, your tests are either all inside the shared example or all outside. There's no way to say "set things up, run _these_ tests, then tear down". With `in_context`, you place `execute_tests` exactly where you want the caller's block to be injected.

**Composing them is awkward.** Nesting `it_behaves_like` inside another `shared_examples` works but reads poorly. `in_context` calls nest naturally, and you can use `in_context` inside a `define_context`.

**They don't accept arguments naturally.** `shared_examples` rely on `let` or params passed via `include_examples`. `in_context` accepts arguments directly, like a method call:

```ruby
# shared_examples way
shared_examples "validates presence" do
  it { is_expected.not_to be_valid }
end

RSpec.describe User do
  context "when email is nil" do
    let(:email) { nil }
    it_behaves_like "validates presence"
  end
  context "when name is nil" do
    let(:name) { nil }
    it_behaves_like "validates presence"
  end
end

# in_context way
RSpec.define_context :validates_presence do |field|
  context "when #{field} is nil" do
    let(field) { nil }
    it { is_expected.not_to be_valid }
  end
end

RSpec.describe User do
  in_context :validates_presence, :email
  in_context :validates_presence, :name
end
```

In short: `in_context` makes reusable test blocks behave more like methods.

## Table of Contents

- [Why not just shared_examples?](#why-not-just-shared_examples)
- [Installation](#installation)
- [Usage](#usage)
  - [Add this into RSpec](#add-this-into-rspec)
  - [Define a new in_context](#define-a-new-in_context)
  - [Use the context](#use-the-context)
  - [Things to know](#things-to-know)
- [Errors](#errors)
- [Examples](#examples)
- [Migrating to 1.2.0](#migrating-to-120)
- [Development](#development)
- [Contributing](#contributing)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rspec_in_context'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rspec_in_context

## Usage

### Add this into RSpec

You must require the gem on top of your spec_helper:
```ruby
require 'rspec_in_context'
```

Then include it into RSpec:
```ruby
RSpec.configure do |config|
  [...]

  config.include RspecInContext
end
```

### Define a new in_context

You can define in_context blocks that are reusable almost anywhere.
They completely look like normal RSpec.

##### Inside a RSpec block (scoped)

```ruby
# A in_context can be named with a symbol or a string
define_context :context_name do
  it 'works' do
    expect(true).to be_truthy
  end
end
```

Those in_context will be scoped to their current `describe`/`context` block.

##### Outside a RSpec block (globally)

Outside of a test you have to use `RSpec.define_context`. Those in_context will be defined globally in your tests.

##### File organization

For global contexts, we recommend creating a `spec/contexts/` directory with one file per context (or per group of related contexts):

```
spec/
  contexts/
    authenticated_request_context.rb
    frozen_time_context.rb
    interactor_contract_context.rb
  spec_helper.rb
```

Then require them in your `spec_helper.rb`:

```ruby
Dir[File.join(__dir__, "contexts", "**", "*.rb")].each { |f| require f }
```

### Use the context

Anywhere in your test description, use a `in_context` block to use a predefined in_context.

**Important**: in_context are scoped to their current `describe`/`context` block. If you need globally defined contexts see `RSpec.define_context`

```ruby
RSpec.define_context :context_name do
  it 'works' do
    expect(true).to be_truthy
  end
end

[...]
RSpec.describe MyClass do
  in_context :context_name # => will execute the 'it works' test here
end
```

### Things to know

#### Inside block execution

* You can choose exactly where your inside test will be used:
By using `execute_tests` in your define context, the test passed when you *use* the context will be executed here

```ruby
RSpec.define_context :authenticated_request do
  let(:user) { create(:user) }

  before { sign_in user }

  context "without authentication" do
    before { sign_out user }

    it "redirects to login" do
      send(http_method, endpoint_path)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  execute_tests
end

[...]

RSpec.describe "Projects", type: :request do
  let(:http_method) { :get }
  let(:endpoint_path) { projects_path }

  in_context :authenticated_request do
    it "returns 200" do
      get projects_path
      expect(response).to have_http_status(:ok)
    end
  end
end
```

The block you pass to `in_context` gets injected exactly where `execute_tests` is placed. Setup, teardown, and built-in tests live together in the context definition. Your specific tests are injected right where they belong.

* You can add variable instantiation relative to your test where you exactly want:

`instantiate_context` is an alias of `execute_tests` so you can't use both.
But it lets you describe what the block will do better.

> **Note**: The old spelling `instanciate_context` still works but is deprecated and will emit a warning.

#### Variable usage

* You can use variables in the in_context definition

```ruby
RSpec.define_context :interactor_contract do |required_fields|
  required_fields.each do |field|
    context "when #{field} is missing" do
      let(field) { nil }

      it "fails" do
        expect(subject).to be_a_failure
      end

      it "reports the breach" do
        expect(subject.breaches).to include(field)
      end
    end
  end
end

[...]

RSpec.describe CreateInvoice do
  subject { described_class.call(amount: amount, client: client) }

  let(:amount) { 100 }
  let(:client) { create(:client) }

  in_context :interactor_contract, %i[amount client]
end
```

#### Scoping

* In_contexts can be scoped inside one another

```ruby
RSpec.define_context :with_frozen_time do
  before { freeze_time }
  execute_tests
end

RSpec.define_context :with_inline_mailer do
  around do |example|
    ActiveJob::Base.queue_adapter = :inline
    ActionMailer::Base.deliveries.clear
    example.run
    ActionMailer::Base.deliveries.clear
    ActiveJob::Base.queue_adapter = :test
  end
  execute_tests
end

[...]

RSpec.describe PasswordReset do
  in_context :with_frozen_time do
    in_context :with_inline_mailer do
      it "sends the reset email with correct timestamp" do
        PasswordReset.call(user)
        expect(ActionMailer::Base.deliveries.last.body)
          .to include(Time.current.to_s)
      end
    end
  end
end
```

* You can also use `in_context` inside a `define_context` to compose contexts together:

```ruby
RSpec.define_context :statistics_processor do
  in_context :interactor_contract, %i[account date]

  it "succeeds" do
    expect(subject).to be_success
  end
end
```

* in_context are bound to their current scope

#### Namespacing

* You can add a namespace to a in_context definition

```ruby
define_context "with valid params", namespace: "users"
```
Or
```ruby
define_context "with valid params", ns: "users"
```
Or
```ruby
RSpec.define_context "with valid params", ns: "users"
```

* When you want to use a namespaced in_context, you have two choices:

Ignore any namespace and it will try to find a corresponding in_context in any namespace (the ones defined without namespace have the priority). **Note**: if the same context name exists in multiple namespaces, an `AmbiguousContextName` error will be raised — you must specify the namespace explicitly.
```ruby
define_context "namespaced context", ns: "namespace name" do
  [...]
end

in_context "namespaced context" # Works if only one namespace has this name
```

Pass a namespace and it will look only in this namespace.
```ruby
define_context "namespaced context", ns: "namespace name" do
  [...]
end

in_context "namespaced context", namespace: "namespace name"
in_context "namespaced context", ns: "namespace name"
```

#### Making `in_context` advertise itself

The fact that a `in_context` block is used inside the test is silent and invisible by default.
`in_context` will still wrap its own execution inside an anonymous context.

But, there's some cases where it helps to make the `in_context` wrap its execution in a named `context` block.
For example:
```ruby
define_context "with my_var defined" do
  before do
    described_class.set_my_var(true)
  end

  it "works"
end

define_context "without my_var defined" do
  it "doesn't work"
end

RSpec.describe MyNiceClass do
  in_context "with my_var defined"
  in_context "without my_var defined"
end
```
Using a `rspec -f doc` will only print "MyNiceClass works" and "MyNiceClass doesn't work" which is not really a good documentation.

So, you can define a context specifying it not to be `silent` or to `print_context`.
For example:
```ruby
define_context "with my_var defined", silent: false do
  before do
    described_class.set_my_var(true)
  end

  it "works"
end

define_context "without my_var defined", print_context: true do
  it "doesn't work"
end

RSpec.describe MyNiceClass do
  in_context "with my_var defined"
  in_context "without my_var defined"
end
```
Will print "MyNiceClass with my_var defined works" and "MyNiceClass without my_var defined doesn't work". Which is valid and readable documentation.

#### Thread-safety & parallel_tests

The context registry is protected by a Mutex so it's safe to use with `parallel_tests` in thread mode.

#### Memory cleanup

For long-running test suites with many dynamically generated contexts, you can free all stored contexts:

```ruby
RspecInContext::InContext.clear_all_contexts!
```

### Errors

| Error | Cause |
|---|---|
| `NoContextFound` | `in_context` refers to a name that doesn't exist or is out of scope |
| `AmbiguousContextName` | Same name exists in multiple namespaces, no namespace specified |
| `InvalidContextName` | `define_context` called with `nil` or empty name |
| `MissingDefinitionBlock` | `define_context` called without a block |

## Examples

The [`examples/`](examples/) directory contains real-world usage patterns:

- **`contexts/`** — Context definitions you'd put in `spec/contexts/` (authentication, interactor contracts, frozen time, job setup, mailer, composed contexts)
- **`usage/`** — Spec files showing how to use those contexts in practice

See [`examples/README.md`](examples/README.md) for the full list.

## Migrating to 1.2.0

### Breaking changes

- **Ruby >= 3.2 required.** Older Rubies are no longer supported.
- **`AmbiguousContextName` error.** If the same context name exists in multiple namespaces and you call `in_context` without specifying a namespace, `AmbiguousContextName` is now raised instead of silently picking one. Fix: add `ns:` to disambiguate.
- **`ActiveSupport` removed.** The gem no longer depends on `activesupport`. This should be transparent, but if you were relying on `HashWithIndifferentAccess` behavior from the gem's internals, note that contexts are now stored in a plain `Hash` with string-normalized keys (symbols and strings still work interchangeably).

### Deprecations

- **`instanciate_context`** is deprecated (typo). Use `instantiate_context` or `execute_tests` instead. The old method still works but emits a warning to `$stderr`.

### New features

- **Input validation**: `define_context` now raises `InvalidContextName` (nil/empty name) and `MissingDefinitionBlock` (no block).
- **`clear_all_contexts!`**: Call `RspecInContext::InContext.clear_all_contexts!` to free all stored contexts for memory cleanup in long-running suites.
- **Thread-safety**: The context registry is now protected by a Mutex for `parallel_tests` in thread mode.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

After setting up the repo, you should run `overcommit --install` to install the different hooks.

Every commit/push is checked by overcommit.

Tool used in dev:

- RSpec
- Rubocop
- Prettier

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/denispasin/rspec_in_context.
