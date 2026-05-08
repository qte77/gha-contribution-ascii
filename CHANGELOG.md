<!-- markdownlint-disable MD024 -->
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

### Fixed

- `bump-and-release.yaml` cleanup no longer deletes the version tag/release on
  failure. Combined with "Enable release immutability", the previous behavior
  permanently burned tag names on every failed dispatch — `v2.3.0` itself
  became unreachable. See #85, #89.

---

## [2.3.1] - 2026-05-08

(`v2.3.0` was burned by failed `bump-and-release.yaml` runs interacting with
release immutability — see issue #85. Released as `v2.3.1`.)

### Added

- `MAX_TARGET` input caps `target_count` to prevent runaway escalation across
  repeated dispatches (`target = max + 1` + append-only `gh-pages` is otherwise
  unbounded). Empty or `0` keeps the legacy uncapped behavior.

### Fixed

- `COMPENSATE` now queries each calendar year a paint spans and merges results.
  Previous logic queried `start_date - 365d` → today, silently exceeding GitHub's
  1-year GraphQL window for backdated paints and falling back to `INTENSITY`.
- Painted commits pin `GIT_AUTHOR_DATE` to `+00:00` so the graph-bucket day no
  longer depends on the runner's local timezone.

### Docs

- Removed inaccurate "ghost contributions persist after `gh-pages` deletion"
  claim from advanced docs (contradicted the README DISCLAIMER, which is correct:
  deleting `gh-pages` clears the graph contributions within ~24h).
- Markdown lint fixes (MD024 disable, MD060 separator pad) and replaced 301-redirected GitHub docs link.
- `lint-md-links` workflow grants `issues: write` for the reusable `notify` job.

---

## [2.2.1] - 2026-03-23

### Changed

- Bump workflow creates signed commits via GitHub API (no external actions)
- `bump-my-version` runs with `commit=false, tag=false` — files only

---

## [2.2.0] - 2026-03-23

### Added

- `BITMAP` input for custom pixel art — 7 comma-separated rows of `0`/`1` (overrides `TEXT`)
- Pacman + cherry example in README

### Changed

- `TEXT` input is now optional when `BITMAP` is provided
- Multiple paintings coexist: appends to existing `gh-pages` instead of orphan-ing each run
- `git push --force` only on first run (orphan); fast-forward push on append

### Fixed

- Post-step `action.yaml not found` error: restores original branch after push
- Paint job in `test-action.yml` always dry-run (v2 lacks BITMAP/append support)

---

## [2.1.2] - 2026-03-22

---

## [2.1.1] - 2026-03-22

---

## [2.1.0] - 2026-03-22

---

## [2.0.4] - 2026-03-22

---

## [2.0.3] - 2026-03-22

---

## [2.0.2] - 2026-03-22

### Changed

- `generate_commit_plan` reads global `BITMAP_ROWS` directly instead of temp file (KISS)
- `generate_commits_for_date` no longer takes `repo_path` param — operates in current directory (KISS)
- `get_start_date` extracted `_adjust_to_sunday` helper to eliminate duplication (DRY)
- Token validation moved to startup in `main.sh` — fails fast before rendering (KISS)
- CodeQL workflow scans open PRs instead of only closed ones
- `delete_branch_pr_tag.sh` now actually deletes the version tag on bump failure
- `test-action.yml` split into two jobs: `test-local` (dry-run `./`) and `paint` (published tag)

### Removed

- Dead `create_painting_repo` function from `generate.sh` (vestigial v1 separate-repo flow)
- Orphaned `summarize-jobs-reusable.yaml` (never called by any workflow)
- Dead PR-merged condition from `bump-my-version.yaml` (only `workflow_dispatch` trigger exists)
- `paint.yml` workflow (use `test-action.yml` for testing; consuming repos use the Marketplace action)
- `render_char` from `font.sh` (test-only, never called by production code)

### Fixed

- README token modes table now matches actual behavior (compensation falls back, not disabled)
- CHANGELOG v1.0.0 test count corrected (42, not 43)
- Added `jq` and `gh` CLI to README prerequisites

---

## [2.0.1] - 2026-03-20

### Added

- Prominent disclaimer about unlimited backdating capability (tested back to 1970-01-04)
- Proof-of-work SVG showing "HI" backdated to Aug 2024

### Changed

- Moved proof-of-work section below example in README
- Contributions are removable by deleting `gh-pages` branch (noted in disclaimer)

---

## [2.0.0] - 2026-03-20

### Added

- Push backdated commits to `gh-pages` branch (counts for contribution graph, no separate repo needed)
- Default `GITHUB_TOKEN` support — no PAT required for basic usage
- Commit identity derived from `github.actor` noreply email (no `read:user` API call needed)
- Proof-of-work SVG in `docs/` showing "HI" pattern backdated to Aug 2024
- Comprehensive README rewrite with usage examples, token modes, and backdating docs

### Changed

- **BREAKING**: Commits now go to `gh-pages` branch instead of a separate `contribution-art` repo
- **BREAKING**: `TOKEN` input is now optional (defaults to `GITHUB_TOKEN`)
- **BREAKING**: Removed `REPO_NAME` input (no longer creates separate repos)
- Identity resolution uses `github.actor` instead of `gh api user/emails`

### Removed

- `REPO_NAME` input and separate repo creation flow
- `gh api user` and `gh api user/emails` API calls (replaced by `github.actor`)

---

## [1.1.0] - 2026-03-20

### Added

- CodeQL workflow (weekly schedule + push/PR triggers, autodiscovery)
- Dependabot config for `github-actions` ecosystem (weekly updates)
- `start_date` workflow dispatch input for backdating contribution graph art
- HI bitmap example in README

### Changed

- `START_DATE` now defaults to today (adjusted to Sunday) instead of 52 weeks ago
- Commit author email resolved from authenticated user's verified GitHub email (was hardcoded `contribution-ascii@github.com`)
- Bumped `actions/checkout` from v4 to v6
- Bumped `callowayproject/bump-my-version` from 0.29.0 to 1.2.7

### Fixed

- Commits were not counted on contribution graph due to unrecognized author email
- Missing `permissions` blocks in `paint.yml` and `test-action.yml` (CodeQL alerts)

### Security

- Added workflow permissions (`contents: read`) to restrict default token scope

---

## [1.0.0] - 2026-03-20

### Added

- Composite GitHub Action (pure bash, no Docker) for painting ASCII text on contribution graphs
- 5x7 bitmap font supporting A-Z, 0-9, space, and common punctuation
- Interference compensation: queries existing contributions via GraphQL API, sets target to max+1 for guaranteed darkest green
- Inverse mode for profiles with heavy existing contributions
- Dry-run mode for previewing bitmap and commit plan without pushing
- `paint.yml` workflow for self-testing via `workflow_dispatch`
- 42 bats-core tests across 5 test files
- `bump-my-version` release workflow

### Fixed

- Double inversion bug where normal and inverse mode produced identical commit plans
- `((r++))` crash under `set -e` when counter starts at 0

### Removed

- Unused bitmap helpers (`get_bitmap_pixel`, `bitmap_dimensions`, `invert_bitmap`)
