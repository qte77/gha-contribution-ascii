#!/usr/bin/env bash
# Generate backdated git commits for contribution graph painting.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=dates.sh
source "${SCRIPT_DIR}/dates.sh"
# shellcheck source=contributions.sh
source "${SCRIPT_DIR}/contributions.sh"

# create_painting_repo: Initialize or reset the dedicated painting repo.
# Args: $1 = repo_path
create_painting_repo() {
    local repo_path="${1}"

    if [[ -d "$repo_path" ]]; then
        rm -rf "$repo_path"
    fi

    mkdir -p "$repo_path"
    cd "$repo_path"
    git init -b main
    git config user.name "contribution-ascii"
    git config user.email "contribution-ascii@github.com"

    # Initial commit
    echo "Contribution graph art" > README.md
    git add README.md
    GIT_AUTHOR_DATE="2000-01-01T00:00:00" GIT_COMMITTER_DATE="2000-01-01T00:00:00" \
        git commit -m "init" --allow-empty
}

# generate_commits_for_date: Create N commits backdated to a specific date.
# Args: $1 = repo_path, $2 = date (YYYY-MM-DD), $3 = count
generate_commits_for_date() {
    local repo_path="${1}" target_date="${2}" count="${3}"

    if [[ "$count" -le 0 ]]; then
        return
    fi

    cd "$repo_path"

    local i
    for ((i = 1; i <= count; i++)); do
        # Vary the timestamp slightly to avoid dedup
        local ts="${target_date}T12:$(printf '%02d' $((i % 60))):$(printf '%02d' $((i / 60 % 60)))"
        echo "${target_date}-${i}" >> contributions.txt
        git add contributions.txt
        GIT_AUTHOR_DATE="$ts" GIT_COMMITTER_DATE="$ts" \
            git commit -m "art: ${target_date} #${i}" --quiet
    done
}

# generate_commit_plan: Build a commit plan from bitmap + dates + compensation.
# Args: $1 = bitmap_rows_file (7 lines), $2 = start_date, $3 = intensity (1-4),
#        $4 = contributions_json (or "none"), $5 = inverse (true/false)
# Output: Lines of "YYYY-MM-DD COUNT" (or "YYYY-MM-DD CONFLICT")
generate_commit_plan() {
    local bitmap_file="${1}" start_date="${2}" intensity="${3}"
    local contributions_json="${4}" inverse="${5:-false}"

    # Read bitmap rows
    local -a bitmap_rows=()
    while IFS= read -r line; do
        bitmap_rows+=("$line")
    done < "$bitmap_file"

    local width=${#bitmap_rows[0]}
    local thresholds
    # Reason: compute_intensity_thresholds handles empty input (returns 0-4 defaults)
    if [[ "$contributions_json" != "none" ]]; then
        thresholds=$(compute_intensity_thresholds "$contributions_json")
    else
        thresholds=$(compute_intensity_thresholds "[]")
    fi

    local col row
    for ((col = 0; col < width; col++)); do
        for ((row = 0; row < 7; row++)); do
            local pixel="${bitmap_rows[$row]:$col:1}"
            local target_date
            target_date=$(bitmap_pos_to_date "$start_date" "$row" "$col")

            local target_level
            if [[ "$inverse" == "true" ]]; then
                # Inverse: pixel ON = gray (0), pixel OFF = high intensity
                if [[ "$pixel" == "1" ]]; then
                    target_level=0
                else
                    target_level="$intensity"
                fi
            else
                # Normal: pixel ON = high intensity, pixel OFF = gray (0)
                if [[ "$pixel" == "1" ]]; then
                    target_level="$intensity"
                else
                    target_level=0
                fi
            fi

            local existing=0
            if [[ "$contributions_json" != "none" ]]; then
                existing=$(get_contribution_count "$contributions_json" "$target_date")
            fi

            local needed
            needed=$(compute_needed_commits "$target_level" "$existing" "$thresholds")
            echo "$target_date $needed"
        done
    done
}
