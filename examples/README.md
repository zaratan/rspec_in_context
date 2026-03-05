# Examples

Real-world usage examples for `rspec_in_context`.

## contexts/

Context definitions you'd put in `spec/contexts/` in a real project:

- **authenticated_request_context.rb** — Authentication setup with built-in unauthenticated test + `execute_tests` for your authenticated tests
- **interactor_contract_context.rb** — Parameterized contract validation for interactor-style service objects
- **frozen_time_context.rb** — Simple setup context using `freeze_time`
- **active_job_context.rb** — `around` hook to run jobs in test mode
- **inline_mailer_context.rb** — Delivers emails synchronously during tests
- **composed_context.rb** — Composing contexts: uses `in_context` inside `define_context`

## usage/

Spec files showing how to use the contexts above:

- **request_spec.rb** — Using `:authenticated_request` in a request spec
- **interactor_spec.rb** — Using `:interactor_expect` for contract validation
- **nested_contexts_spec.rb** — Nesting `:with_frozen_time` and `:with_inline_mailer`
- **composed_context_spec.rb** — Using `:service_processor` (which itself uses `:interactor_expect`)
