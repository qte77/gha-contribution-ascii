#!/usr/bin/env bash
# Map bitmap matrix positions to calendar dates.
# Row 0 = Sunday, Row 6 = Saturday. Each column = 1 week.

set -euo pipefail

# get_start_date: Calculate the start date (Sunday) for rendering.
# Args: $1 = optional start date (YYYY-MM-DD), defaults to 52 weeks ago adjusted to Sunday
# Output: YYYY-MM-DD (always a Sunday)
get_start_date() {
    local input_date="${1:-}"

    if [[ -n "$input_date" ]]; then
        # Validate and adjust to previous Sunday if needed
        local dow
        dow=$(date -d "$input_date" +%u 2>/dev/null) || {
            echo "ERROR: Invalid date: $input_date" >&2
            return 1
        }
        # %u: Monday=1, Sunday=7
        if [[ "$dow" -eq 7 ]]; then
            echo "$input_date"
        else
            date -d "$input_date - $dow days" +%Y-%m-%d
        fi
    else
        # Default: 52 weeks ago, adjusted to Sunday
        local today
        today=$(date +%Y-%m-%d)
        local dow
        dow=$(date -d "$today" +%u)
        local days_back=$(( 52 * 7 ))
        if [[ "$dow" -ne 7 ]]; then
            days_back=$(( days_back + dow ))
        fi
        date -d "$today - $days_back days" +%Y-%m-%d
    fi
}

# bitmap_pos_to_date: Convert bitmap position (row, col) to a calendar date.
# Args: $1 = start_date (Sunday), $2 = row (0=Sun, 6=Sat), $3 = col (week index)
# Output: YYYY-MM-DD
bitmap_pos_to_date() {
    local start_date="${1}" row="${2}" col="${3}"
    local days_offset=$(( col * 7 + row ))
    date -d "$start_date + $days_offset days" +%Y-%m-%d
}

# generate_date_map: Generate a full date map for all bitmap positions.
# Args: $1 = start_date, $2 = num_columns (weeks), $3 = num_rows (7)
# Output: Lines of "ROW COL YYYY-MM-DD"
generate_date_map() {
    local start_date="${1}" num_cols="${2}" num_rows="${3:-7}"

    local col row
    for ((col = 0; col < num_cols; col++)); do
        for ((row = 0; row < num_rows; row++)); do
            local target_date
            target_date=$(bitmap_pos_to_date "$start_date" "$row" "$col")
            echo "$row $col $target_date"
        done
    done
}

# date_to_git_timestamp: Format a date for GIT_AUTHOR_DATE / GIT_COMMITTER_DATE.
# Args: $1 = YYYY-MM-DD
# Output: "YYYY-MM-DDT12:00:00" (noon UTC)
date_to_git_timestamp() {
    echo "${1}T12:00:00"
}
