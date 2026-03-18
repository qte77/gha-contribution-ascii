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

@test "compute_intensity_thresholds with empty contributions" {
    local empty='[]'
    local result
    result=$(compute_intensity_thresholds "$empty")
    local lines
    lines=$(echo "$result" | wc -l)
    [ "$lines" -eq 5 ]
    # First line (level 0) should be 0
    local level0
    level0=$(echo "$result" | head -1)
    [ "$level0" -eq 0 ]
}

@test "compute_intensity_thresholds with contributions produces 5 levels" {
    local result
    result=$(compute_intensity_thresholds "$MOCK_CONTRIBUTIONS")
    local lines
    lines=$(echo "$result" | wc -l)
    [ "$lines" -eq 5 ]
}

@test "compute_intensity_thresholds level 0 is always 0" {
    local result
    result=$(compute_intensity_thresholds "$MOCK_CONTRIBUTIONS")
    local level0
    level0=$(echo "$result" | sed -n '1p')
    [ "$level0" -eq 0 ]
}

@test "compute_intensity_thresholds level 4 equals max count" {
    local result
    result=$(compute_intensity_thresholds "$MOCK_CONTRIBUTIONS")
    local level4
    level4=$(echo "$result" | sed -n '5p')
    # Max in mock data is 10
    [ "$level4" -eq 10 ]
}

@test "compute_intensity_thresholds levels are monotonically increasing" {
    local result
    result=$(compute_intensity_thresholds "$MOCK_CONTRIBUTIONS")
    local prev=0
    while IFS= read -r val; do
        [ "$val" -ge "$prev" ]
        prev="$val"
    done <<< "$result"
}

@test "compute_needed_commits level 0 with no existing returns 0" {
    local thresholds="0
1
2
3
4"
    local result
    result=$(compute_needed_commits 0 0 "$thresholds")
    [ "$result" = "0" ]
}

@test "compute_needed_commits level 0 with existing returns CONFLICT" {
    local thresholds="0
1
2
3
4"
    local result
    result=$(compute_needed_commits 0 3 "$thresholds")
    [ "$result" = "CONFLICT" ]
}

@test "compute_needed_commits level 4 with no existing returns threshold" {
    local thresholds="0
1
2
3
4"
    local result
    result=$(compute_needed_commits 4 0 "$thresholds")
    [ "$result" -eq 4 ]
}

@test "compute_needed_commits level 4 with partial existing subtracts" {
    local thresholds="0
1
2
3
4"
    local result
    result=$(compute_needed_commits 4 2 "$thresholds")
    [ "$result" -eq 2 ]
}

@test "compute_needed_commits returns 0 when existing exceeds target" {
    local thresholds="0
1
2
3
4"
    local result
    result=$(compute_needed_commits 2 5 "$thresholds")
    [ "$result" -eq 0 ]
}
