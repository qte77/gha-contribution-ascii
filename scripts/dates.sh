#!/usr/bin/env bash
# Map bitmap matrix positions to calendar dates.
# Row 0 = Sunday, Row 6 = Saturday. Each column = 1 week.

set -euo pipefail

# _adjust_to_sunday: Adjust a date to its preceding Sunday (or return as-is if already Sunday).
# Args: $1 = date (YYYY-MM-DD)
# Output: YYYY-MM-DD (always a Sunday)
_adjust_to_sunday() {
    local d="${1}"
    local dow
    dow=$(date -d "$d" +%u 2>/dev/null) || {
        echo "ERROR: Invalid date: $d" >&2
        return 1
    }
    # %u: Monday=1, Sunday=7
    if [[ "$dow" -eq 7 ]]; then
        echo "$d"
    else
        date -d "$d - $dow days" +%Y-%m-%d
    fi
}

# get_start_date: Calculate the start date (Sunday) for rendering.
# Args: $1 = optional start date (YYYY-MM-DD), defaults to today adjusted to Sunday
# Output: YYYY-MM-DD (always a Sunday)
get_start_date() {
    local input_date="${1:-}"
    _adjust_to_sunday "${input_date:-$(date +%Y-%m-%d)}"
}

# bitmap_pos_to_date: Convert bitmap position (row, col) to a calendar date.
# Args: $1 = start_date (Sunday), $2 = row (0=Sun, 6=Sat), $3 = col (week index)
# Output: YYYY-MM-DD
bitmap_pos_to_date() {
    local start_date="${1}" row="${2}" col="${3}"
    local days_offset=$(( col * 7 + row ))
    date -d "$start_date + $days_offset days" +%Y-%m-%d
}
