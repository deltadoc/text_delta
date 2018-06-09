# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [1.4.0] - 2018-06-09
### Added
  - Introduced experimental support for disabling unicode support through
    `:text_delta.support_unicode` config. This is useful, because disabling
    grapheme handling drastically speeds up all string operations (used heavily).
    If you implementation does not need support of unicode, using this config
    can greatly improve performance of the library.

### Fixed
  - Small performance optimisations by avoiding unnecessary `String.length`
    calls

## [1.3.0] - 2017-12-29
### Added
  - `&TextDelta.lines/1` and `&TextDelta.lines!/1`
  - `&TextDelta.diff/2` and `&TextDelta.diff!/2`

## [1.2.0] - 2017-05-29
### Added
  - `&TextDelta.apply/2` and `&TextDelta.apply!/2`

### Changed
  - Moved repository under `deltadoc` organisation.
  - Text state is now represented with `TextDelta.state` type rather than
    `TextDelta.document` throughout the codebase. `TextDelta.document` is still
    there in form of an alias for `TextDelta.state`.

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

[Unreleased]: https://github.com/everzet/text_delta/compare/v1.4.0...HEAD
[1.4.0]: https://github.com/everzet/text_delta/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/everzet/text_delta/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/everzet/text_delta/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/everzet/text_delta/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/everzet/text_delta/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/everzet/text_delta/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/everzet/text_delta/compare/cdaf5769ba3abb36aa6a6e2431662164a5a30945...v1.0.0
