#!/usr/bin/env bash
# 5x7 bitmap font for ASCII contribution graph rendering.
# Each character is 5 columns wide, 7 rows tall.
# '1' = pixel on, '0' = pixel off.
# Usage: source this file, then call render_char or render_text.

set -euo pipefail

# Font data: associative array mapping character -> 7 lines of 5-bit strings
declare -gA FONT

# Letters A-Z
FONT[A]="01110 10001 10001 11111 10001 10001 10001"
FONT[B]="11110 10001 10001 11110 10001 10001 11110"
FONT[C]="01110 10001 10000 10000 10000 10001 01110"
FONT[D]="11100 10010 10001 10001 10001 10010 11100"
FONT[E]="11111 10000 10000 11110 10000 10000 11111"
FONT[F]="11111 10000 10000 11110 10000 10000 10000"
FONT[G]="01110 10001 10000 10111 10001 10001 01110"
FONT[H]="10001 10001 10001 11111 10001 10001 10001"
FONT[I]="01110 00100 00100 00100 00100 00100 01110"
FONT[J]="00111 00010 00010 00010 00010 10010 01100"
FONT[K]="10001 10010 10100 11000 10100 10010 10001"
FONT[L]="10000 10000 10000 10000 10000 10000 11111"
FONT[M]="10001 11011 10101 10101 10001 10001 10001"
FONT[N]="10001 11001 10101 10011 10001 10001 10001"
FONT[O]="01110 10001 10001 10001 10001 10001 01110"
FONT[P]="11110 10001 10001 11110 10000 10000 10000"
FONT[Q]="01110 10001 10001 10001 10101 10010 01101"
FONT[R]="11110 10001 10001 11110 10100 10010 10001"
FONT[S]="01111 10000 10000 01110 00001 00001 11110"
FONT[T]="11111 00100 00100 00100 00100 00100 00100"
FONT[U]="10001 10001 10001 10001 10001 10001 01110"
FONT[V]="10001 10001 10001 10001 01010 01010 00100"
FONT[W]="10001 10001 10001 10101 10101 11011 10001"
FONT[X]="10001 10001 01010 00100 01010 10001 10001"
FONT[Y]="10001 10001 01010 00100 00100 00100 00100"
FONT[Z]="11111 00001 00010 00100 01000 10000 11111"

# Digits 0-9
FONT[0]="01110 10001 10011 10101 11001 10001 01110"
FONT[1]="00100 01100 00100 00100 00100 00100 01110"
FONT[2]="01110 10001 00001 00010 00100 01000 11111"
FONT[3]="11111 00010 00100 00010 00001 10001 01110"
FONT[4]="00010 00110 01010 10010 11111 00010 00010"
FONT[5]="11111 10000 11110 00001 00001 10001 01110"
FONT[6]="00110 01000 10000 11110 10001 10001 01110"
FONT[7]="11111 00001 00010 00100 01000 01000 01000"
FONT[8]="01110 10001 10001 01110 10001 10001 01110"
FONT[9]="01110 10001 10001 01111 00001 00010 01100"

# Punctuation and space
FONT[" "]="00000 00000 00000 00000 00000 00000 00000"
FONT[!]="00100 00100 00100 00100 00100 00000 00100"
FONT[.]="00000 00000 00000 00000 00000 00000 00100"
FONT[-]="00000 00000 00000 11111 00000 00000 00000"
FONT[_]="00000 00000 00000 00000 00000 00000 11111"
FONT[:]="00000 00000 00100 00000 00100 00000 00000"

# render_char: Output 7 rows of a single character bitmap.
# Args: $1 = character (single char, uppercase)
# Output: 7 lines, each a string of 0s and 1s (5 chars wide)
render_char() {
    local char="${1:-}"
    local data="${FONT[$char]:-}"

    if [[ -z "$data" ]]; then
        # Unknown character: render as blank
        data="${FONT[" "]}"
    fi

    local row
    for row in $data; do
        echo "$row"
    done
}

# render_text: Render a string as a 7-row bitmap matrix.
# Args: $1 = text string (will be uppercased)
# Output: 7 lines, each representing one row of the full bitmap.
#         Characters are separated by 1-column gap (0).
render_text() {
    local text
    text="$(echo "${1:-}" | tr '[:lower:]' '[:upper:]')"
    local len=${#text}

    if [[ $len -eq 0 ]]; then
        return
    fi

    # Build 7 row strings
    local -a rows=("" "" "" "" "" "" "")

    local i char
    for ((i = 0; i < len; i++)); do
        char="${text:$i:1}"
        local data="${FONT[$char]:-${FONT[" "]}}"

        # Add 1-column gap between characters (not before first)
        if [[ $i -gt 0 ]]; then
            for ((r = 0; r < 7; r++)); do
                rows[$r]="${rows[$r]}0"
            done
        fi

        local r=0
        local row
        for row in $data; do
            rows[$r]="${rows[$r]}${row}"
            r=$((r + 1))
        done
    done

    # Output the 7 rows
    local r
    for ((r = 0; r < 7; r++)); do
        echo "${rows[$r]}"
    done
}
