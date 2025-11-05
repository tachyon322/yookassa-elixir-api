# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-11-05

### Fixed
- Corrected documentation formatting and improved examples in `lib/yookassa.ex`

### Changed
- Updated version to 0.2.0 and made `plug_cowboy` dependency optional

## [0.1.3] - 2025-11-05

### Changed
- Improved and standardized documentation across the library. Docstrings now provide clearer explanations, examples, and parameter descriptions.
- Updated `README.md` to include a section on idempotency and clarify API function return values.
- Translated comments in `mix.exs` and `lib/yookassa.ex` to English for better maintainability.

## [0.1.2] - 2025-11-04

### Fixed
- Critical bug fix in client configuration handling: eliminated compile-time configuration dependencies by removing Application.compile_env! usage, now reads configuration at runtime using Application.get_env/2 in base_req/0, ensuring main project configuration is loaded; added validation that raises a clear error message if Yookassa configuration is missing.

## [0.1.1] - 2025-10-01

### Added
- Initial release of Yookassa Elixir client for API v3
- Support for creating, capturing, canceling payments
- Support for creating and retrieving refunds
- Built-in webhook handler for payment and refund events

### Changed
- Updated README.md with webhook port configuration details