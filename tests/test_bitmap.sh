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

@test "text_to_bitmap HELLO width is 29" {
    # H(5)+gap+E(5)+gap+L(5)+gap+L(5)+gap+O(5) = 25+4gaps = 29
    text_to_bitmap "HELLO"
    [ "$BITMAP_WIDTH" -eq 29 ]
}
