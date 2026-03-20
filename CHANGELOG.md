# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html), i.e. MAJOR.MINOR.PATCH (Breaking.Feature.Patch).

Types of changes:

- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Removed` for now removed features.
- `Fixed` for any bug fixes.
- `Security` in case of vulnerabilities.

## [Unreleased]

---

## [1.0.0] - 2026-03-20

### Added

- Composite GitHub Action (pure bash, no Docker) for painting ASCII text on contribution graphs
- 5x7 bitmap font supporting A-Z, 0-9, space, and common punctuation
- Interference compensation: queries existing contributions via GraphQL API, sets target to max+1 for guaranteed darkest green
- Inverse mode for profiles with heavy existing contributions
- Dry-run mode for previewing bitmap and commit plan without pushing
- `paint.yml` workflow for self-testing via `workflow_dispatch`
- 43 bats-core tests across 5 test files
- `bump-my-version` release workflow

### Fixed

- Double inversion bug where normal and inverse mode produced identical commit plans
- `((r++))` crash under `set -e` when counter starts at 0

### Removed

- Unused bitmap helpers (`get_bitmap_pixel`, `bitmap_dimensions`, `invert_bitmap`)
