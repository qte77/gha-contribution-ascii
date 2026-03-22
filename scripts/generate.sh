#!/usr/bin/env bash
# Generate backdated git commits for contribution graph painting.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=dates.sh
source "${SCRIPT_DIR}/dates.sh"
# shellcheck source=contributions.sh
source "${SCRIPT_DIR}/contributions.sh"

# generate_commits_for_date: Create N commits backdated to a specific date.
# Args: $1 = date (YYYY-MM-DD), $2 = count
generate_commits_for_date() {
    local target_date="${1}" count="${2}"

    if [[ "$count" -le 0 ]]; then
        return
    fi

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
# Reads: BITMAP_ROWS global array (set by text_to_bitmap)
# Args: $1 = start_date, $2 = target_count,
#        $3 = contributions_json (or "none"), $4 = inverse (true/false)
# Output: Lines of "YYYY-MM-DD COUNT" (or "YYYY-MM-DD CONFLICT")
generate_commit_plan() {
    local start_date="${1}" target_count="${2}"
    local contributions_json="${3}" inverse="${4:-false}"

    local width=${#BITMAP_ROWS[0]}

    local col row
    for ((col = 0; col < width; col++)); do
        for ((row = 0; row < 7; row++)); do
            local pixel="${BITMAP_ROWS[$row]:$col:1}"
            local target_date
            target_date=$(bitmap_pos_to_date "$start_date" "$row" "$col")

            # Determine if this pixel should be green or gray
            local wants_green
            if [[ "$inverse" == "true" ]]; then
                [[ "$pixel" == "0" ]] && wants_green=true || wants_green=false
            else
                [[ "$pixel" == "1" ]] && wants_green=true || wants_green=false
            fi

            local existing=0
            if [[ "$contributions_json" != "none" ]]; then
                existing=$(get_contribution_count "$contributions_json" "$target_date")
            fi

            if [[ "$wants_green" == "true" ]]; then
                local needed=$((target_count - existing))
                [[ $needed -lt 0 ]] && needed=0
                echo "$target_date $needed"
            else
                if [[ "$existing" -gt 0 ]]; then
                    echo "$target_date CONFLICT"
                else
                    echo "$target_date 0"
                fi
            fi
        done
    done
}
