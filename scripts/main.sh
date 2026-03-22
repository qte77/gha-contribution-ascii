#!/usr/bin/env bash
# Orchestrator for GitHub Contribution Graph ASCII Writer.
# Called by action.yaml or directly for local testing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# bitmap.sh sources font.sh; generate.sh sources dates.sh + contributions.sh
# shellcheck source=bitmap.sh
source "${SCRIPT_DIR}/bitmap.sh"
# shellcheck source=generate.sh
source "${SCRIPT_DIR}/generate.sh"

main() {
    local text="${INPUT_TEXT:-}"
    local token="${INPUT_TOKEN:-}"
    local intensity="${INPUT_INTENSITY:-4}"
    local inverse="${INPUT_INVERSE:-false}"
    local start_date="${INPUT_START_DATE:-}"
    local compensate="${INPUT_COMPENSATE:-true}"
    local dry_run="${INPUT_DRY_RUN:-false}"
    local github_actor="${INPUT_GITHUB_ACTOR:-}"

    if [[ -z "$text" ]]; then
        echo "::error::TEXT input is required"
        exit 1
    fi

    if [[ "$dry_run" != "true" && -z "$token" ]]; then
        echo "::error::TOKEN is required for non-dry-run mode"
        exit 1
    fi

    echo "=== Contribution Graph ASCII Writer ==="
    echo "Text: $text"
    echo "Fallback intensity: $intensity"
    echo "Inverse: $inverse"
    echo "Dry run: $dry_run"

    # Step 1: Render text to bitmap
    echo ""
    echo "--- Rendering bitmap ---"
    text_to_bitmap "$text"
    echo "Bitmap dimensions: ${BITMAP_WIDTH}w x ${BITMAP_HEIGHT}h"

    # Preview bitmap (swap display chars for inverse so user sees final appearance)
    local row
    for ((row = 0; row < BITMAP_HEIGHT; row++)); do
        local display="${BITMAP_ROWS[$row]}"
        if [[ "$inverse" == "true" ]]; then
            display="${display//1/░}"
            display="${display//0/█}"
        else
            display="${display//1/█}"
            display="${display//0/░}"
        fi
        echo "$display"
    done

    # Step 2: Calculate start date
    start_date=$(get_start_date "$start_date")
    echo ""
    echo "Start date: $start_date"

    # Check bitmap fits in 52 weeks
    if [[ $BITMAP_WIDTH -gt 52 ]]; then
        echo "::warning::Text is ${BITMAP_WIDTH} columns wide but graph is 52 columns. Text will be truncated."
    fi

    # Resolve identity from github.actor (no API call needed)
    # Reason: GitHub counts contributions if commit email matches a verified account email.
    # The noreply address is a verified alias for every GitHub account.
    local username="${github_actor}"
    local user_email="${github_actor}@users.noreply.github.com"
    if [[ -n "$username" ]]; then
        echo "Commit identity: $username <$user_email>"
    fi

    # Step 3: Query existing contributions and compute target
    local contributions_json="none"
    local target_count="$intensity"
    if [[ "$compensate" == "true" && -n "$username" && -n "$token" ]]; then
        echo ""
        echo "--- Querying existing contributions (full year) ---"
        local year_ago
        year_ago=$(date -d "$start_date - 365 days" +%Y-%m-%d 2>/dev/null || date -d "365 days ago" +%Y-%m-%d)
        local today
        today=$(date +%Y-%m-%d)
        contributions_json=$(query_contributions "$token" "$username" "$year_ago" "$today") || {
            echo "::warning::Could not query contributions. Using fallback intensity=$intensity."
            contributions_json="none"
        }

        if [[ "$contributions_json" != "none" ]]; then
            local max_count
            max_count=$(get_max_contribution_count "$contributions_json")
            # Reason: exceed the user's max to guarantee darkest green (top quartile)
            target_count=$((max_count + 1))
            echo "Max existing contributions/day: $max_count -> target: $target_count"
        fi
    fi

    # Step 4: Generate commit plan
    echo ""
    echo "--- Commit plan ---"
    local plan
    plan=$(generate_commit_plan "$start_date" "$target_count" "$contributions_json" "$inverse")

    # Count totals
    local total_commits=0 conflict_count=0
    local line
    while IFS= read -r line; do
        local count="${line##* }"
        if [[ "$count" == "CONFLICT" ]]; then
            conflict_count=$((conflict_count + 1))
        elif [[ "$count" -gt 0 ]]; then
            total_commits=$((total_commits + count))
        fi
    done <<< "$plan"

    echo "Total commits needed: $total_commits"
    if [[ $conflict_count -gt 0 ]]; then
        echo "::warning::${conflict_count} cells have conflicts (existing contributions on days that need to be gray). Consider using INVERSE=true."
    fi

    if [[ "$dry_run" == "true" ]]; then
        echo ""
        echo "--- Dry run: commit plan ---"
        echo "$plan" | while IFS= read -r line; do
            local pdate="${line%% *}" pcount="${line##* }"
            if [[ "$pcount" != "0" ]]; then
                echo "  $pdate -> $pcount commits"
            fi
        done
        echo ""
        echo "Dry run complete. No commits were made."
        return 0
    fi

    # Step 5: Setup gh-pages branch
    # Reason: GitHub counts contributions on default branch and gh-pages only.
    # gh-pages works with GITHUB_TOKEN (no PAT required) and doesn't pollute main.
    echo ""
    echo "--- Setting up gh-pages branch ---"

    git config user.name "$username"
    git config user.email "$user_email"

    # Create orphan gh-pages branch (clean history)
    git checkout --orphan gh-pages
    git rm -rf . > /dev/null 2>&1 || true
    echo "Contribution graph art - ${text} (${start_date})" > contributions.txt
    git add contributions.txt
    local init_date
    init_date="$(date -u +%Y-%m-%dT%H:%M:%S)"
    GIT_AUTHOR_DATE="$init_date" GIT_COMMITTER_DATE="$init_date" \
        git commit -m "init" --quiet

    # Step 6: Generate backdated commits
    echo ""
    echo "--- Generating commits ---"
    while IFS= read -r line; do
        local pdate="${line%% *}" pcount="${line##* }"
        if [[ "$pcount" == "CONFLICT" || "$pcount" == "0" ]]; then
            continue
        fi
        generate_commits_for_date "$pdate" "$pcount"
    done <<< "$plan"

    # Step 7: Force-push gh-pages
    echo ""
    echo "--- Pushing gh-pages ---"
    git push --force origin gh-pages

    echo ""
    echo "Done! ${total_commits} backdated commits on gh-pages as ${user_email}."
    echo "Contributions should appear on your graph within ~1 hour."
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
