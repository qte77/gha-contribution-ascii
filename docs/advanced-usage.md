# Advanced Usage

## Token Modes

| Token | Capabilities | Limitations |
|---|---|---|
| `GITHUB_TOKEN` (default) | Push commits, backdate | Compensation attempted but falls back to `INTENSITY` (lacks `read:user` scope) |
| PAT with `read:user` | Full compensation | Requires manual secret setup |

## Existing Contributions and Interference

The graph shows **total contributions per day** across all repos. The action handles this:

| Scenario | Result | Action |
|---|---|---|
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
- **Deleting `gh-pages` removes the contributions from the graph** (within ~24h, per the project DISCLAIMER). Useful for resetting after runaway escalation.
- **Quartile coloring** is per-year and relative to your yearly max ([GitHub docs](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-github-profile/managing-contribution-settings-on-your-profile/viewing-contributions-on-your-profile)). Multi-year paints query each spanned year so target beats every year's max.

## Capping target with MAX_TARGET

Without a cap, `target = max + 1` plus append-only `gh-pages` causes target to climb by 1 every dispatch — past runs become the new ceiling. Set `MAX_TARGET` to bound it:

```yaml
- uses: qte77/gha-contribution-ascii@v2
  with:
    BITMAP: "..."
    MAX_TARGET: "30"   # target will not exceed 30 even if max+1 is higher
```

Empty or `0` keeps the legacy uncapped behavior.
