# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/zaratan/rspec_in_context/compare/v1.1.0.1...HEAD
[1.1.0.1]: https://github.com/zaratan/rspec_in_context/releases/tag/v1.1.0.1
[1.1.0]: https://github.com/zaratan/rspec_in_context/releases/tag/v1.1.0
[1.0.1.2]: https://github.com/zaratan/rspec_in_context/releases/tag/v1.0.1.2
