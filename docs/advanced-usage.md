# Advanced Usage

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

The action renders text or `BITMAP` to this 7-row matrix, optionally queries existing contributions for compensation, then creates backdated commits on `gh-pages` (force on first run, append after). Contributions index within ~1h.

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

## Limitations

- Existing real contributions can't be hidden — days with activity always render green
- Future-dated commits index unpredictably (past dates are reliable)
- Ghost contributions persist after deleting `gh-pages` — counts only ever go up
- Bitmap wider than 52 columns exceeds the visible graph window
- Compensation needs a PAT (default `GITHUB_TOKEN` lacks `read:user` scope)

## Token Modes

| Token | Capabilities | Limitations |
| --- | --- | --- |
| `GITHUB_TOKEN` (default) | Push commits, backdate | Compensation attempted but falls back to `INTENSITY` (lacks `read:user` scope) |
| PAT with `read:user` | Full compensation | Requires manual secret setup |

## Existing Contributions and Interference

The graph shows **total contributions per day** across all repos. The action handles this:

| Scenario | Result | Action |
| --- | --- | --- |
| Art needs green, day is empty | Works perfectly | Adds target commits |
| Art needs green, day has commits | Works, compensated | Subtracts existing from target |
| Art needs gray, day has commits | **Conflict** | Logs warning, skips cell |
| New contributions after painting | Art degrades | Re-run to repaint |

**`COMPENSATE=true`** (default): Queries your full year of contributions, finds your max contribution day, and sets the target to max+1. Requires a PAT with `read:user` scope. With `GITHUB_TOKEN`, falls back to `INTENSITY` value.

**`INVERSE=true`**: Swaps text/background — text becomes gray, background becomes green. Use this for busy profiles.

## Multiple Paintings

The action supports appending: the first run creates an orphan `gh-pages`, subsequent runs append commits. This allows multiple paintings at different date ranges to coexist. Each overlay increases commits per cell, producing darker green (quartile-based coloring).

To clear all paintings, delete the `gh-pages` branch and repaint from scratch.

## Platform Quirks

- **Past-dated commits** index quickly (minutes).
- **Future-dated commits** index unpredictably — some ranges appear instantly, others never. Recreating `gh-pages` does not unstick blocked ranges.
- **Deleting `gh-pages` removes the contributions from the graph** (within ~24h, per the README disclaimer). Useful for resetting after runaway escalation.
- **Quartile coloring** is per-year and relative to your yearly max ([GitHub docs](https://docs.github.com/en/account-and-profile/how-tos/contribution-settings/viewing-contributions-on-your-profile)). Multi-year paints query each spanned year so target beats every year's max.

## Capping target with MAX_TARGET

Without a cap, `target = max + 1` plus append-only `gh-pages` causes target to climb by 1 every dispatch — past runs become the new ceiling. Set `MAX_TARGET` to bound it:

```yaml
- uses: qte77/gha-contribution-ascii@v2
  with:
    BITMAP: "..."
    MAX_TARGET: "30"   # target will not exceed 30 even if max+1 is higher
```

Empty or `0` keeps the legacy uncapped behavior.

## Development

### Prerequisites

- [bats-core](https://github.com/bats-core/bats-core) for testing
- `jq` for JSON processing (contributions compensation)
- `gh` CLI for GitHub API queries

### Running Tests

```bash
bats tests/
```
