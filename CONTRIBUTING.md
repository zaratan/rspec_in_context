# Contributing to rspec_in_context

Thanks for wanting to help improve this gem. Bug reports, pull requests and
ideas are all welcome.

## Setting up your dev environment

You'll need Ruby `>= 3.2` (the CI matrix runs on 3.2, 3.3, 3.4 and 4.0).

```sh
git clone https://github.com/denispasin/rspec_in_context.git
cd rspec_in_context
bin/setup
```

`bin/setup` runs `bundle install`. Once that's done, install the git hooks so
your changes are checked locally before they hit CI:

```sh
bundle exec overcommit --install
```

For an interactive prompt to experiment with the gem, use:

```sh
bin/console
```

## Running the checks

Before opening a PR, make sure the three checks pass locally — the same ones
CI runs:

```sh
bundle exec rspec            # tests + SimpleCov coverage (min 90%)
bundle exec rubocop          # lint
bundle exec prettier --check 'lib/**/*.rb' 'spec/**/*.rb' '*.gemspec'
```

Formatting issues can be fixed automatically:

```sh
bundle exec rubocop -A
bundle exec prettier --write 'lib/**/*.rb' 'spec/**/*.rb' '*.gemspec'
```

## Writing changes

- **Keep the scope small.** One PR, one concern. If you find unrelated cleanup
  while working, split it into a separate PR.
- **Add tests.** The gem relies on a `BlockDeliveryGuard` (see
  `spec/support/block_delivery_guard.rb`) that detects silently lost test
  blocks — so a missing assertion won't go unnoticed, but a missing scenario
  will.
- **Update the CHANGELOG.** Add an entry under an `## [Unreleased]` section
  describing the change from a user's perspective.
- **Keep public API changes visible.** If you touch `in_context`,
  `define_context`, `execute_tests`, or any documented behaviour, update the
  README and `LLMS.md`.

## Commit messages

We don't enforce Conventional Commits, but prefer short imperative subjects
(`Fix ambiguous namespace lookup`, not `fixed the bug`). Reference the PR or
issue number in the body when relevant.

## Releasing (maintainers)

1. Bump the version in `lib/rspec_in_context/version.rb`.
2. Add a dated entry in `CHANGELOG.md`.
3. Commit on `main` — the version bump is validated by the
   `verify_version_change` workflow.
4. `bundle exec rake release` tags the commit, pushes it, and publishes the
   `.gem` to rubygems.org.

## Reporting issues

Open an issue on
[GitHub](https://github.com/denispasin/rspec_in_context/issues) with:

- Ruby and RSpec versions
- The smallest reproduction you can manage (ideally a failing spec)
- What you expected vs. what happened

For security issues, please open a private advisory rather than a public issue.
