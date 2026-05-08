#!/usr/bin/env bats
# Tests for contributions.sh: contribution query and compensation logic.

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../scripts" && pwd)"

setup() {
    source "${SCRIPT_DIR}/contributions.sh"
}

# Mock contribution data for testing
MOCK_CONTRIBUTIONS='[
    {"date": "2025-01-05", "contributionCount": 0},
    {"date": "2025-01-06", "contributionCount": 3},
    {"date": "2025-01-07", "contributionCount": 10},
    {"date": "2025-01-08", "contributionCount": 0},
    {"date": "2025-01-09", "contributionCount": 5},
    {"date": "2025-01-10", "contributionCount": 0},
    {"date": "2025-01-11", "contributionCount": 8}
]'

@test "get_contribution_count returns correct count for existing date" {
    local result
    result=$(get_contribution_count "$MOCK_CONTRIBUTIONS" "2025-01-06")
    [ "$result" -eq 3 ]
}

@test "get_contribution_count returns 0 for date with no contributions" {
    local result
    result=$(get_contribution_count "$MOCK_CONTRIBUTIONS" "2025-01-05")
    [ "$result" -eq 0 ]
}

@test "get_contribution_count returns 0 for missing date" {
    local result
    result=$(get_contribution_count "$MOCK_CONTRIBUTIONS" "2025-12-25")
    [ "$result" -eq 0 ]
}

@test "get_max_contribution_count returns max from data" {
    local result
    result=$(get_max_contribution_count "$MOCK_CONTRIBUTIONS")
    [ "$result" -eq 10 ]
}

@test "get_max_contribution_count returns 0 for empty array" {
    local result
    result=$(get_max_contribution_count "[]")
    [ "$result" -eq 0 ]
}

@test "get_max_contribution_count with single entry" {
    local result
    result=$(get_max_contribution_count '[{"date": "2025-01-01", "contributionCount": 7}]')
    [ "$result" -eq 7 ]
}

@test "merge_contribution_jsons returns same length when given one array" {
    local result
    result=$(merge_contribution_jsons "$MOCK_CONTRIBUTIONS")
    [ "$(echo "$result" | jq 'length')" -eq 7 ]
}

@test "merge_contribution_jsons concatenates two arrays" {
    local a='[{"date": "2025-12-31", "contributionCount": 5}]'
    local b='[{"date": "2026-01-01", "contributionCount": 12}]'
    local result
    result=$(merge_contribution_jsons "$a" "$b")
    [ "$(echo "$result" | jq 'length')" -eq 2 ]
}

@test "merge_contribution_jsons handles empty arrays" {
    local result
    result=$(merge_contribution_jsons '[]' '[]')
    [ "$(echo "$result" | jq 'length')" -eq 0 ]
}

@test "merge_contribution_jsons with no args returns empty array" {
    local result
    result=$(merge_contribution_jsons)
    [ "$(echo "$result" | jq 'length')" -eq 0 ]
}

@test "get_max_contribution_count picks max across merged years" {
    local a='[{"date": "2025-12-31", "contributionCount": 5}]'
    local b='[{"date": "2026-01-01", "contributionCount": 12}]'
    local merged
    merged=$(merge_contribution_jsons "$a" "$b")
    local result
    result=$(get_max_contribution_count "$merged")
    [ "$result" -eq 12 ]
}

@test "get_contribution_count finds date from second year in merged data" {
    local a='[{"date": "2025-12-31", "contributionCount": 5}]'
    local b='[{"date": "2026-01-01", "contributionCount": 12}]'
    local merged
    merged=$(merge_contribution_jsons "$a" "$b")
    local result
    result=$(get_contribution_count "$merged" "2026-01-01")
    [ "$result" -eq 12 ]
}

@test "years_in_range returns single year for same-year span" {
    local result
    result=$(years_in_range "2025-03-30" "2025-06-14")
    [ "$result" = "2025" ]
}

@test "years_in_range returns two years for Dec-Jan span" {
    local result
    result=$(years_in_range "2025-10-26" "2026-01-03")
    local count
    count=$(echo "$result" | wc -l)
    [ "$count" -eq 2 ]
    [ "$(echo "$result" | sed -n '1p')" = "2025" ]
    [ "$(echo "$result" | sed -n '2p')" = "2026" ]
}

@test "years_in_range returns three years for multi-year span" {
    local result
    result=$(years_in_range "2024-12-31" "2026-01-01")
    [ "$(echo "$result" | wc -l)" -eq 3 ]
}
