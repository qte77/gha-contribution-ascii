#!/usr/bin/env bats
# Tests for bitmap.sh: text-to-bitmap matrix conversion.

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../scripts" && pwd)"

setup() {
    source "${SCRIPT_DIR}/bitmap.sh"
}

@test "text_to_bitmap HI sets BITMAP_HEIGHT to 7" {
    text_to_bitmap "HI"
    [ "$BITMAP_HEIGHT" -eq 7 ]
}

@test "text_to_bitmap HI sets BITMAP_WIDTH to 11" {
    text_to_bitmap "HI"
    [ "$BITMAP_WIDTH" -eq 11 ]
}

@test "text_to_bitmap HI BITMAP_ROWS has 7 elements" {
    text_to_bitmap "HI"
    [ "${#BITMAP_ROWS[@]}" -eq 7 ]
}

@test "text_to_bitmap ABC BITMAP_WIDTH is 17" {
    text_to_bitmap "ABC"
    [ "$BITMAP_WIDTH" -eq 17 ]
}

@test "text_to_bitmap empty string BITMAP_WIDTH is 0" {
    text_to_bitmap ""
    [ "$BITMAP_WIDTH" -eq 0 ]
}

@test "get_bitmap_pixel returns correct value" {
    text_to_bitmap "A"
    # Row 0 of A is "01110"
    local p0 p1 p4
    p0=$(get_bitmap_pixel 0 0)
    p1=$(get_bitmap_pixel 0 1)
    p4=$(get_bitmap_pixel 0 4)
    [ "$p0" = "0" ]
    [ "$p1" = "1" ]
    [ "$p4" = "0" ]
}

@test "bitmap_dimensions outputs correct format" {
    text_to_bitmap "HI"
    local dims
    dims=$(bitmap_dimensions)
    [ "$dims" = "11 7" ]
}

@test "invert_bitmap flips all pixels" {
    text_to_bitmap " "
    # Space is all zeros
    invert_bitmap
    # Should now be all ones
    local row
    for row in "${BITMAP_ROWS[@]}"; do
        [ "$row" = "11111" ]
    done
}

@test "invert_bitmap double inversion restores original" {
    text_to_bitmap "A"
    local -a original=("${BITMAP_ROWS[@]}")
    invert_bitmap
    invert_bitmap
    local i
    for ((i = 0; i < 7; i++)); do
        [ "${BITMAP_ROWS[$i]}" = "${original[$i]}" ]
    done
}

@test "text_to_bitmap HELLO width is 29" {
    # H(5)+gap+E(5)+gap+L(5)+gap+L(5)+gap+O(5) = 25+4gaps = 29
    text_to_bitmap "HELLO"
    [ "$BITMAP_WIDTH" -eq 29 ]
}
