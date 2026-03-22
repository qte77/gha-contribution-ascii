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

# parse_raw_bitmap tests

@test "parse_raw_bitmap sets correct dimensions" {
    parse_raw_bitmap "01110,11111,11111,11111,11111,11111,01110"
    [ "$BITMAP_WIDTH" -eq 5 ]
    [ "$BITMAP_HEIGHT" -eq 7 ]
    [ "${#BITMAP_ROWS[@]}" -eq 7 ]
}

@test "parse_raw_bitmap stores rows correctly" {
    parse_raw_bitmap "111,000,101,010,101,000,111"
    [ "${BITMAP_ROWS[0]}" = "111" ]
    [ "${BITMAP_ROWS[3]}" = "010" ]
    [ "${BITMAP_ROWS[6]}" = "111" ]
}

@test "parse_raw_bitmap rejects wrong row count" {
    run parse_raw_bitmap "111,000,111"
    [ "$status" -eq 1 ]
}

@test "parse_raw_bitmap handles 10-col pacman bitmap" {
    parse_raw_bitmap "0111000001,1111100010,1111000100,1110011110,1111011110,1111101100,0111000000"
    [ "$BITMAP_WIDTH" -eq 10 ]
    [ "${BITMAP_ROWS[0]}" = "0111000001" ]
    [ "${BITMAP_ROWS[6]}" = "0111000000" ]
}
