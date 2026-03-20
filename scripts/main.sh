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

    # Resolve username and email once (needed for compensation, repo setup, and commit attribution)
    local username="" user_email=""
    if [[ -n "$token" ]]; then
        username=$(gh api user --jq '.login' 2>/dev/null) || {
            echo "::warning::Could not determine username."
            username=""
        }
        # Reason: GitHub only counts contributions if commit email matches a verified account email
        user_email=$(gh api user/emails --jq '[.[] | select(.verified)] | first | .email' 2>/dev/null) || {
            echo "::warning::Could not determine user email. Falling back to noreply."
            user_email=""
        }
        if [[ -z "$user_email" ]]; then
            user_email="${username}@users.noreply.github.com"
        fi
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

    # Step 5: Setup branch in current repo
    if [[ -z "$token" ]]; then
        echo "::error::TOKEN is required for non-dry-run mode"
        exit 1
    fi

    local repo_full="${INPUT_GITHUB_REPOSITORY:-}"
    if [[ -z "$repo_full" ]]; then
        echo "::error::GITHUB_REPOSITORY not set"
        exit 1
    fi

    local branch_name="contribution-art/${start_date}"
    echo ""
    echo "--- Setting up branch ${branch_name} ---"

    # Configure git identity
    local commit_name="${username:-contribution-ascii}"
    local commit_email="${user_email:-contribution-ascii@github.com}"
    git config user.name "$commit_name"
    git config user.email "$commit_email"

    # Create orphan branch for clean history
    git checkout --orphan "$branch_name"
    git rm -rf . > /dev/null 2>&1 || true
    echo "Contribution graph art - ${text} (${start_date})" > contributions.txt
    git add contributions.txt
    GIT_AUTHOR_DATE="2000-01-01T00:00:00" GIT_COMMITTER_DATE="2000-01-01T00:00:00" \
        git commit -m "init" --quiet

    # Step 6: Generate backdated commits
    echo ""
    echo "--- Generating commits ---"
    local work_dir
    work_dir=$(pwd)
    while IFS= read -r line; do
        local pdate="${line%% *}" pcount="${line##* }"
        if [[ "$pcount" == "CONFLICT" || "$pcount" == "0" ]]; then
            continue
        fi
        generate_commits_for_date "$work_dir" "$pdate" "$pcount"
    done <<< "$plan"

    # Step 7: Push branch, wait for GitHub to register, then clean up
    echo ""
    echo "--- Pushing branch ${branch_name} ---"
    git push --force origin "$branch_name"

    echo ""
    echo "Waiting 30s for GitHub to register contributions..."
    sleep 30

    echo "--- Cleaning up branch ${branch_name} ---"
    git push origin --delete "$branch_name"

    echo ""
    echo "Done! ${total_commits} backdated commits pushed and branch cleaned up."
    echo "Contributions should appear on your graph within ~1 hour."
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
