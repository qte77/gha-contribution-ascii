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
