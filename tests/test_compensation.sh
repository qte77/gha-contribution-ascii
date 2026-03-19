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
