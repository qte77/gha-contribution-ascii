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
    local repo_name="${INPUT_REPO_NAME:-contribution-art}"
    local intensity="${INPUT_INTENSITY:-4}"
    local inverse="${INPUT_INVERSE:-false}"
    local start_date="${INPUT_START_DATE:-}"
    local compensate="${INPUT_COMPENSATE:-true}"
    local dry_run="${INPUT_DRY_RUN:-false}"

    if [[ -z "$text" ]]; then
        echo "::error::TEXT input is required"
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

    if [[ "$inverse" == "true" ]]; then
        invert_bitmap
    fi

    # Preview bitmap
    local row
    for ((row = 0; row < BITMAP_HEIGHT; row++)); do
        local display="${BITMAP_ROWS[$row]}"
        display="${display//1/█}"
        display="${display//0/░}"
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

    # Resolve username once (needed for compensation and repo setup)
    local username=""
    if [[ -n "$token" ]]; then
        username=$(gh api user --jq '.login' 2>/dev/null) || {
            echo "::warning::Could not determine username."
            username=""
        }
    fi

    # Step 3: Query existing contributions and compute target
    local contributions_json="none"
    local target_count="$intensity"
    if [[ "$compensate" == "true" && -n "$username" ]]; then
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
    local bitmap_file
    bitmap_file=$(mktemp)
    printf '%s\n' "${BITMAP_ROWS[@]}" > "$bitmap_file"

    local plan
    plan=$(generate_commit_plan "$bitmap_file" "$start_date" "$target_count" "$contributions_json" "$inverse")
    rm -f "$bitmap_file"

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

    # Step 5: Create/reset painting repo
    if [[ -z "$token" ]]; then
        echo "::error::TOKEN is required for non-dry-run mode"
        exit 1
    fi

    echo ""
    echo "--- Setting up painting repo ---"
    if [[ -z "$username" ]]; then
        echo "::error::Could not determine GitHub username. TOKEN may be invalid."
        exit 1
    fi
    local repo_full="${username}/${repo_name}"

    # Create private repo if it doesn't exist
    if ! gh repo view "$repo_full" &>/dev/null; then
        echo "Creating private repo: $repo_full"
        gh repo create "$repo_full" --private --description "Contribution graph art (auto-generated)" || {
            echo "::error::Failed to create repo $repo_full"
            exit 1
        }
    fi

    local work_dir
    work_dir=$(mktemp -d)
    create_painting_repo "$work_dir"

    # Step 6: Generate backdated commits
    echo ""
    echo "--- Generating commits ---"
    while IFS= read -r line; do
        local pdate="${line%% *}" pcount="${line##* }"
        if [[ "$pcount" == "CONFLICT" || "$pcount" == "0" ]]; then
            continue
        fi
        generate_commits_for_date "$work_dir" "$pdate" "$pcount"
    done <<< "$plan"

    # Step 7: Push
    echo ""
    echo "--- Pushing to ${repo_full} ---"
    cd "$work_dir"
    git remote add origin "https://x-access-token:${token}@github.com/${repo_full}.git"
    git push --force origin main

    echo ""
    echo "Done! Contributions should appear on your graph within ~1 hour."

    # Cleanup
    rm -rf "$work_dir"
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
