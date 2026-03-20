# Contribution Graph ASCII

![Version](https://img.shields.io/badge/version-1.0.0-8A2BE2)

GitHub Action that writes ASCII text on your GitHub contribution graph (the green squares timeline on your profile).

For version history see the [CHANGELOG](CHANGELOG.md).

## Features

- Pure bash composite action (no Docker, no Python runtime)
- 5x7 bitmap font: A-Z, 0-9, space, common punctuation
- **Interference compensation**: queries existing contributions and adjusts commit counts
- Inverse mode for profiles with heavy existing contributions
- Dry-run mode for previewing without pushing

## Example

Default text `HI` rendered as a 7×11 bitmap (7 rows = days, 11 columns = weeks):

```text
█░░░█░░███░
█░░░█░░░█░░
█░░░█░░░█░░
█████░░░█░░
█░░░█░░░█░░
█░░░█░░░█░░
█░░░█░░███░
```

## How It Works

1. Renders text as a 7-row bitmap (7 rows = 7 days/week)
2. Maps each column to a week, each row to a day of the week
3. Queries your existing contribution counts via GraphQL API
4. Computes how many commits are needed per day to reach the target intensity
5. Creates backdated commits in a dedicated private repo
6. Pushes — contributions appear on your graph within ~1 hour

## Usage

```yaml
- uses: qte77/gha-contribution-ascii@v1
  with:
    TEXT: "HELLO"
    TOKEN: ${{ secrets.CONTRIBUTION_PAT }}
```

### Inputs

| Input | Default | Required | Description |
|---|---|---|---|
| `TEXT` | — | yes | ASCII text to render |
| `TOKEN` | — | yes | PAT with `repo`, `read:user`, `user:email` scopes |
| `REPO_NAME` | `contribution-art` | no | Dedicated private repo name |
| `INTENSITY` | `4` | no | Fallback commit count when `COMPENSATE` is off |
| `INVERSE` | `false` | no | Invert colors (helps with existing contributions) |
| `START_DATE` | auto | no | Start date (YYYY-MM-DD), defaults to 52 weeks ago |
| `COMPENSATE` | `true` | no | Query existing contributions and adjust |
| `DRY_RUN` | `false` | no | Preview without pushing |

### Dry Run

Preview the bitmap and commit plan without pushing:

```yaml
- uses: qte77/gha-contribution-ascii@v1
  with:
    TEXT: "HI"
    TOKEN: ${{ secrets.CONTRIBUTION_PAT }}
    DRY_RUN: "true"
```

### Existing Contributions and Interference

The graph shows **total contributions per day** across all repos. The action handles this:

| Scenario | Result | Action |
|---|---|---|
| Art needs green, day is empty | Works perfectly | Adds target commits |
| Art needs green, day has commits | Works, compensated | Subtracts existing from target |
| Art needs gray, day has commits | **Conflict** | Logs warning, skips cell |
| New contributions after painting | Art degrades | Re-run to repaint |

**`COMPENSATE=true`** (default): Queries your full year of contributions, finds your max contribution day, and sets the target to max+1. This guarantees painted pixels land in the top quartile (darkest green). Existing counts on painted days are subtracted automatically.

**`INVERSE=true`**: Swaps text/background — text becomes gray, background becomes green. Since background only *adds* commits, existing contributions help rather than hurt. Use this for busy profiles.

### Scheduled Repaint

Add a daily cron to automatically maintain the art against new contributions:

```yaml
on:
  schedule:
    - cron: '0 6 * * *'  # daily at 06:00 UTC
```

**Tips**:

- Run `DRY_RUN=true` first to preview conflicts
- Use `INVERSE=true` if your graph already has many contributions
- Schedule daily repaints to keep art intact despite new activity

## Limitations

- Cannot make a day with existing contributions appear gray (fundamental GitHub limitation)
- Text wider than 52 characters exceeds the visible graph window
- Graph updates are cached by GitHub (~1 hour delay)

## Development

### Prerequisites

- [bats-core](https://github.com/bats-core/bats-core) for testing

### Running Tests

```bash
bats tests/
```

## License

[BSD-3-Clause](LICENSE.md)
