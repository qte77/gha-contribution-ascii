#!/usr/bin/env bats
# Tests for dates.sh: date mapping for contribution graph.

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../scripts" && pwd)"

setup() {
    source "${SCRIPT_DIR}/dates.sh"
}

@test "get_start_date with Sunday returns same date" {
    # 2025-01-05 is a Sunday
    local result
    result=$(get_start_date "2025-01-05")
    [ "$result" = "2025-01-05" ]
}

@test "get_start_date with Monday returns previous Sunday" {
    # 2025-01-06 is a Monday -> should return 2025-01-05
    local result
    result=$(get_start_date "2025-01-06")
    [ "$result" = "2025-01-05" ]
}

@test "get_start_date with Saturday returns previous Sunday" {
    # 2025-01-11 is a Saturday -> should return 2025-01-05
    local result
    result=$(get_start_date "2025-01-11")
    [ "$result" = "2025-01-05" ]
}

@test "get_start_date with Wednesday returns previous Sunday" {
    # 2025-01-08 is a Wednesday -> should return 2025-01-05
    local result
    result=$(get_start_date "2025-01-08")
    [ "$result" = "2025-01-05" ]
}

@test "get_start_date with invalid date fails" {
    run get_start_date "not-a-date"
    [ "$status" -ne 0 ]
}

@test "bitmap_pos_to_date row 0 col 0 returns start date" {
    local result
    result=$(bitmap_pos_to_date "2025-01-05" 0 0)
    [ "$result" = "2025-01-05" ]
}

@test "bitmap_pos_to_date row 6 col 0 returns start+6 days (Saturday)" {
    local result
    result=$(bitmap_pos_to_date "2025-01-05" 6 0)
    [ "$result" = "2025-01-11" ]
}

@test "bitmap_pos_to_date row 0 col 1 returns start+7 days (next Sunday)" {
    local result
    result=$(bitmap_pos_to_date "2025-01-05" 0 1)
    [ "$result" = "2025-01-12" ]
}

@test "bitmap_pos_to_date row 3 col 2 returns start+17 days" {
    # col 2 * 7 + row 3 = 17 days
    local result
    result=$(bitmap_pos_to_date "2025-01-05" 3 2)
    [ "$result" = "2025-01-22" ]
}
