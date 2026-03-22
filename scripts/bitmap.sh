#!/usr/bin/env bash
# Text-to-bitmap matrix conversion.
# Sources font.sh and provides bitmap dimensions and manipulation.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=font.sh
source "${SCRIPT_DIR}/font.sh"

# text_to_bitmap: Convert text to a 7-row bitmap matrix stored in a global array.
# Args: $1 = text string
# Sets: BITMAP_ROWS (array of 7 strings), BITMAP_WIDTH (integer), BITMAP_HEIGHT (7)
declare -ga BITMAP_ROWS=()
declare -g BITMAP_WIDTH=0
declare -g BITMAP_HEIGHT=7

# parse_raw_bitmap: Parse comma-separated rows of 0/1 into the global bitmap.
# Args: $1 = "row0,row1,...,row6" (7 rows, each a string of 0s and 1s)
# Sets: BITMAP_ROWS, BITMAP_WIDTH, BITMAP_HEIGHT
parse_raw_bitmap() {
    local input="${1:-}"
    BITMAP_ROWS=()
    BITMAP_WIDTH=0
    BITMAP_HEIGHT=7

    IFS=',' read -ra rows <<< "$input"
    if [[ ${#rows[@]} -ne 7 ]]; then
        echo "::error::BITMAP must have exactly 7 rows, got ${#rows[@]}"
        exit 1
    fi

    local r
    for r in "${rows[@]}"; do
        BITMAP_ROWS+=("$r")
    done
    BITMAP_WIDTH=${#BITMAP_ROWS[0]}
}

text_to_bitmap() {
    local text="${1:-}"
    BITMAP_ROWS=()
    BITMAP_WIDTH=0
    BITMAP_HEIGHT=7

    if [[ -z "$text" ]]; then
        return
    fi

    local r=0
    while IFS= read -r line; do
        BITMAP_ROWS+=("$line")
        if [[ $r -eq 0 ]]; then
            BITMAP_WIDTH=${#line}
        fi
        r=$((r + 1))
    done < <(render_text "$text")
}
