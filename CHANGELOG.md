# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.1] - 2026-03-05
### Added
- `LLMS.md` — comprehensive API reference for LLMs
- `examples/` directory with real-world usage patterns (contexts and specs)

### Changed
- Complete rewrite of `README.md` with better structure, real-world examples, and comparison with `shared_examples`

## [1.2.0] - 2026-01-27
### Breaking
- **BREAKING** Minimum Ruby version is now 3.2
- **BREAKING** `in_context` without namespace now raises `AmbiguousContextName` if the same context name exists in multiple namespaces. Specify the namespace explicitly to resolve.
- Removed `codacy-coverage` dependency (incompatible with Ruby 4)

### Added
- Nested `in_context` with blocks now work correctly (uses a stack instead of a single thread-local variable)
- Input validation: `define_context` raises `InvalidContextName` for nil/empty names and `MissingDefinitionBlock` when no block is given
- `AmbiguousContextName` error when a context name exists in multiple namespaces and no namespace is specified

### Changed
- CI now tests Ruby 3.2, 3.3, 3.4, and head
- GitHub Actions updated to v4 (checkout, setup-node)
- Node updated to 20 in CI
- Rubocop config uses `plugins` instead of deprecated `require`

### Fixed
- Thread-safety for nested `in_context` calls with blocks (previous implementation silently overwrote the outer block)
- Non-deterministic context resolution when multiple namespaces contained the same context name
- Tests no longer depend on execution order (random order enabled)
- Removed all global variables from test suite

## [1.1.0.3] - 2021-01-13
### Added
- Reformating code with Prettier-ruby

## [1.1.0.2] - 2021-01-08
### Changed
- Wrapping silent in_context in anonymous contexts

## [1.1.0.1] - 2020-12-27
This is a release in order to test all type of actions

### Added
- Cache support in github actions for ease of development


## [1.1.0] - 2020-12-27
### Added
- **BREAKING** Option to silence in_context block. They used to always wrap themself into a context block with their name. This is not the case anymore. All in_context are silent unless explicitely declared as not. 

## [1.0.1.2] - 2020-12-26
### Added
- Changelog
- Support ruby 3.0

[Unreleased]: https://github.com/zaratan/rspec_in_context/compare/v1.2.1...HEAD
[1.2.1]: https://github.com/zaratan/rspec_in_context/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/zaratan/rspec_in_context/compare/v1.1.0.3...v1.2.0
[1.1.0.3]: https://github.com/zaratan/rspec_in_context/compare/v1.1.0.2...v1.1.0.3
[1.1.0.2]: https://github.com/zaratan/rspec_in_context/compare/v1.1.0.1...v1.1.0.2
[1.1.0.1]: https://github.com/zaratan/rspec_in_context/releases/tag/v1.1.0.1
[1.1.0]: https://github.com/zaratan/rspec_in_context/releases/tag/v1.1.0
[1.0.1.2]: https://github.com/zaratan/rspec_in_context/releases/tag/v1.0.1.2
