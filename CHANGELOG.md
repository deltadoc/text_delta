# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [1.1.0] - 2017-05-02
### Added
  - Property-based tests for composition, transformation and compaction

### Fixed
  - Insert duplication bug during delta compaction
  - Delete/Delete misbehaviour bug during composition

### Changed
  - `TextDelta.Delta` is now just `TextDelta`
  - `TextDelta.Delta.*` modules moved into `TextDelta.*`
  - `TextDelta` now generates and operates on `%TextDelta{}` struct
  - `TextDelta.Delta` is still there and works like before in form of a BC
    layer, so your existing code would still work while you upgrade. To be
    removed in 2.x
  - Slightly improved documentation across modules

## [1.0.2] - 2017-03-29
### Fixed
  - Bug when composition of delete with larger retain resulted in broken delta

### Removed
  - Config

## [1.0.1] - 2017-03-23
### Added
  - Test cases for string-keyed maps as attributes
  - More context and information to Readme
  - Changelog

### Changed
  - Improved documentation across modules
  - Cleaned up code to follow [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)

## [1.0.0] - 2017-03-18
### Added
  - Delta construction and manipulation logic
  - Attributes support in `insert` and `retain`
  - Delta composition and transformation with attributes supported

[Unreleased]: https://github.com/everzet/text_delta/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/everzet/text_delta/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/everzet/text_delta/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/everzet/text_delta/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/everzet/text_delta/compare/cdaf5769ba3abb36aa6a6e2431662164a5a30945...v1.0.0
