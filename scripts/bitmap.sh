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

# get_bitmap_pixel: Get pixel value at (row, col).
# Args: $1 = row (0-6), $2 = col (0-based)
# Output: "0" or "1"
get_bitmap_pixel() {
    local row="${1}" col="${2}"
    local line="${BITMAP_ROWS[$row]:-}"
    echo "${line:$col:1}"
}

# bitmap_dimensions: Output "WIDTH HEIGHT" of current bitmap.
bitmap_dimensions() {
    echo "${BITMAP_WIDTH} ${BITMAP_HEIGHT}"
}

# invert_bitmap: Flip all 0s to 1s and vice versa in BITMAP_ROWS.
invert_bitmap() {
    local -a inverted=()
    local row
    for row in "${BITMAP_ROWS[@]}"; do
        inverted+=("$(echo "$row" | tr '01' '10')")
    done
    BITMAP_ROWS=("${inverted[@]}")
}
