# gha-contribution-ascii

![Version](https://img.shields.io/badge/version-2.2.1-8A2BE2)
![License](https://img.shields.io/badge/license-Apache--2.0-blue)
![Test Action](https://github.com/qte77/gha-contribution-ascii/actions/workflows/test-action.yml/badge.svg)
![CodeFactor](https://www.codefactor.io/repository/github/qte77/gha-contribution-ascii/badge)
![CodeQL](https://github.com/qte77/gha-contribution-ascii/actions/workflows/codeql.yaml/badge.svg)
![Dependabot](https://img.shields.io/badge/dependabot-enabled-025e8c)
![BATS](https://img.shields.io/badge/tests-BATS-blue)

> **DISCLAIMER**: This action creates commits with arbitrary `GIT_AUTHOR_DATE` timestamps.
> There is **no technical limit** on how far back commits can be backdated — including
> dates before Git (2005), before GitHub (2008), and even before Unix epoch (1970).
> We have successfully written "FIRLEFANZ" to the contribution graph starting
> **January 4, 1970**. Use responsibly. Contributions generated this way are
> indistinguishable from real activity on the graph. To undo, delete the `gh-pages`
> branch — contributions disappear within 24 hours.

GitHub Action that writes ASCII text on your GitHub contribution graph using backdated commits. Works with the default `GITHUB_TOKEN` — no PAT required.

For version history see the [CHANGELOG](CHANGELOG.md).

## Features

- Pure bash composite action — no Docker, no Python runtime
- Works with the default `GITHUB_TOKEN` (PAT only needed for compensation)
- 5×7 font (A–Z, 0–9, space, punctuation) or raw `BITMAP` for custom pixel art
- Backdating via `START_DATE`; multi-year paints supported (compensation queries each spanned year)
- Pushes to `gh-pages` so art stays out of `main`
- Compensation, inverse, and dry-run modes built in

## How It Works

7 rows = days of the week, each column = one week. The action renders text or `BITMAP` to a 7-row matrix, optionally queries existing contributions for compensation, then creates backdated commits on `gh-pages` (force on first run, append after). Contributions index within ~1h.

## Example

Default text `HI` rendered as a 7x11 bitmap (7 rows = days, 11 columns = weeks):

```text
█░░░█░░███░
█░░░█░░░█░░
█░░░█░░░█░░
█████░░░█░░
█░░░█░░░█░░
█░░░█░░░█░░
█░░░█░░███░
```

### Proof of Work

"HI" painted on the contribution graph starting August 4, 2024 (backdated from March 2026):

![Contribution graph showing HI pattern from August 2024](docs/contribution-proof-2024.svg)

Verified via GitHub GraphQL API — each green cell has 4+ backdated commits authored as `<user>@users.noreply.github.com`.

## Usage

### Minimal (defaults to today)

```yaml
permissions:
  contents: write

steps:
  - uses: qte77/gha-contribution-ascii@v2
    with:
      TEXT: "HI"
```

No `TOKEN` input needed — the action uses the default `GITHUB_TOKEN` automatically.

### Backdate to a specific date

```yaml
- uses: qte77/gha-contribution-ascii@v2
  with:
    TEXT: "HI"
    START_DATE: "2024-08-04"
```

### Custom pixel art with BITMAP

```yaml
# Pacman eating a cherry (10 cols × 7 rows)
- uses: qte77/gha-contribution-ascii@v2
  with:
    BITMAP: "0111000001,1111100010,1111000100,1110011110,1111011110,1111101100,0111000000"
    START_DATE: "2025-10-26"
```

```text
░███░░░░░█
█████░░░█░
████░░░█░░
███░░████░
████░████░
█████░██░░
░███░░░░░░
```

### Full workflow with schedule

```yaml
name: Paint Contribution Graph
on:
  schedule:
    - cron: '0 6 * * *'
  workflow_dispatch:
    inputs:
      text:
        description: "Text to render"
        default: "HI"
      start_date:
        description: "Start date (YYYY-MM-DD), defaults to today"
      dry_run:
        type: boolean
        default: false

permissions:
  contents: write

jobs:
  paint:
    runs-on: ubuntu-latest
    steps:
      - uses: qte77/gha-contribution-ascii@v2
        with:
          TEXT: ${{ inputs.text || 'HI' }}
          START_DATE: ${{ inputs.start_date }}
          DRY_RUN: ${{ inputs.dry_run || 'false' }}
```

### Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `TEXT` | no* | - | ASCII text to render (ignored when `BITMAP` is set) |
| `BITMAP` | no* | - | Raw bitmap: 7 comma-separated rows of `0`/`1`. Overrides `TEXT` |
| `TOKEN` | no | `GITHUB_TOKEN` | GitHub token (default works, PAT for compensation) |
| `INTENSITY` | no | `4` | Fallback commit count when `COMPENSATE` is off |
| `MAX_TARGET` | no | `""` | Cap on `target_count` to prevent runaway escalation. Empty/0 = uncapped |
| `INVERSE` | no | `false` | Invert colors (helps with existing contributions) |
| `START_DATE` | no | today | Start date (YYYY-MM-DD), adjusted to Sunday |
| `COMPENSATE` | no | `true` | Query existing contributions and adjust |
| `DRY_RUN` | no | `false` | Preview without pushing |

*Either `TEXT` or `BITMAP` is required.

### Dry Run

Preview the bitmap and commit plan without pushing:

```yaml
- uses: qte77/gha-contribution-ascii@v2
  with:
    TEXT: "HI"
    DRY_RUN: "true"
```

For token modes, interference handling, and multiple paintings see [Advanced Usage](docs/advanced-usage.md).

## Limitations

- Existing real contributions can't be hidden — days with activity always render green
- Future-dated commits index unpredictably (past dates are reliable)
- Ghost contributions persist after deleting `gh-pages` — counts only ever go up
- Bitmap wider than 52 columns exceeds the visible graph window
- Compensation needs a PAT (default `GITHUB_TOKEN` lacks `read:user` scope)

See [Advanced Usage](docs/advanced-usage.md) for indexing quirks, multi-overlay behavior, and quartile coloring details.

## Development

### Prerequisites

- [bats-core](https://github.com/bats-core/bats-core) for testing
- `jq` for JSON processing (contributions compensation)
- `gh` CLI for GitHub API queries

### Running Tests

```bash
bats tests/
```

## License

[Apache-2.0](LICENSE)
