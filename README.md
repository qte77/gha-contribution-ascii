# Contribution Graph ASCII

GitHub Action that writes ASCII text on your GitHub contribution graph (the green squares timeline on your profile).

## Features

- Pure bash composite action (no Docker, no Python runtime)
- 5x7 bitmap font: A-Z, 0-9, space, common punctuation
- **Interference compensation**: queries existing contributions and adjusts commit counts
- Inverse mode for profiles with heavy existing contributions
- Dry-run mode for previewing without pushing

## How It Works

1. Renders text as a 7-row bitmap (7 rows = 7 days/week)
2. Maps each column to a week, each row to a day of the week
3. Queries your existing contribution counts via GraphQL API
4. Computes how many commits are needed per day to reach the target intensity
5. Creates backdated commits in a dedicated private repo
6. Pushes — contributions appear on your graph within ~1 hour

## Usage

```yaml
- uses: qte77/gha-contribution-ascii@main
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
| `INTENSITY` | `4` | no | Commit intensity level (1-4) |
| `INVERSE` | `false` | no | Invert colors (helps with existing contributions) |
| `START_DATE` | auto | no | Start date (YYYY-MM-DD), defaults to 52 weeks ago |
| `COMPENSATE` | `true` | no | Query existing contributions and adjust |
| `DRY_RUN` | `false` | no | Preview without pushing |

### Dry Run

Preview the bitmap and commit plan without pushing:

```yaml
- uses: qte77/gha-contribution-ascii@main
  with:
    TEXT: "HI"
    TOKEN: ${{ secrets.CONTRIBUTION_PAT }}
    DRY_RUN: "true"
```

### The Interference Problem

If you have real contributions on days where the art needs gray (0 commits), those cells will show green instead. The action warns about conflicts and suggests `INVERSE: "true"` as a workaround, since inverse art only needs high-intensity cells (adding commits on top of existing ones works fine).

## Limitations

- Cannot make a day with existing contributions appear gray
- Text wider than 52 characters won't fit in the visible graph
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
