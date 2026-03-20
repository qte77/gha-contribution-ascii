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
        # Default: today, adjusted to previous Sunday
        local today
        today=$(date +%Y-%m-%d)
        local dow
        dow=$(date -d "$today" +%u)
        # %u: Monday=1, Sunday=7
        if [[ "$dow" -eq 7 ]]; then
            echo "$today"
        else
            date -d "$today - $dow days" +%Y-%m-%d
        fi
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
