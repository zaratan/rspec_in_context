# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

rspec_in_context is a Ruby gem that enhances RSpec's `shared_examples` by providing a more flexible `in_context` pattern. It allows defining reusable test contexts that behave more like methods, supporting block passing and variable injection.

## Commands

```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rspec

# Run a single test file
bundle exec rspec spec/rspec_in_context/in_context_spec.rb

# Run a specific test by line number
bundle exec rspec spec/rspec_in_context/in_context_spec.rb:42

# Lint code
bundle exec rubocop

# Auto-fix lint issues
bundle exec rubocop -a

# Format with prettier
bundle exec rbprettier --write '**/*.rb'
```

## Architecture

The gem has three main components in `lib/rspec_in_context/`:

- **in_context.rb**: Core module containing the DSL methods (`define_context`, `in_context`, `execute_tests`/`instanciate_context`). Contexts are stored in a hash keyed by namespace and name. The `Context` struct holds the block, owner class, name, namespace, and silent flag.

- **context_management.rb**: Handles context scoping by prepending `RSpec::Core::ExampleGroup.subclass` to remove contexts when their defining describe/context block completes.

- **rspec_in_context.rb**: Entry point that wires up the gem and provides `RSpec.define_context` for global context definitions.

## Key Concepts

- **Scoped vs Global contexts**: `define_context` inside a describe block is scoped to that block. `RSpec.define_context` outside creates global contexts.
- **execute_tests/instanciate_context**: Placeholder in a context definition where the block passed to `in_context` gets injected.
- **Namespacing**: Contexts can be namespaced via `ns:` or `namespace:` to avoid naming collisions.
- **Silent mode**: By default, `in_context` wraps in an anonymous context. Set `silent: false` or `print_context: true` to include the context name in test output.

## Testing Notes

Tests are order-dependent due to context isolation tests. Random order is intentionally disabled in spec_helper.rb.
