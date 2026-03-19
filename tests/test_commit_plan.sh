#!/usr/bin/env bats
# End-to-end tests: text -> bitmap -> dates -> commit plan.

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../scripts" && pwd)"

setup() {
    source "${SCRIPT_DIR}/bitmap.sh"
    source "${SCRIPT_DIR}/generate.sh"
}

@test "commit plan for single space produces all zero counts" {
    text_to_bitmap " "
    local bitmap_file
    bitmap_file=$(mktemp -p "${BATS_TMPDIR}")
    printf '%s\n' "${BITMAP_ROWS[@]}" > "$bitmap_file"

    local plan
    plan=$(generate_commit_plan "$bitmap_file" "2025-01-05" 4 "none" "false")
    rm -f "$bitmap_file"

    # All pixels are 0 for space, so all counts should be 0
    while IFS= read -r line; do
        local count="${line##* }"
        [ "$count" = "0" ]
    done <<< "$plan"
}

@test "commit plan for I has non-zero counts" {
    text_to_bitmap "I"
    local bitmap_file
    bitmap_file=$(mktemp -p "${BATS_TMPDIR}")
    printf '%s\n' "${BITMAP_ROWS[@]}" > "$bitmap_file"

    local plan
    plan=$(generate_commit_plan "$bitmap_file" "2025-01-05" 4 "none" "false")
    rm -f "$bitmap_file"

    local has_nonzero=false
    while IFS= read -r line; do
        local count="${line##* }"
        if [[ "$count" -gt 0 ]]; then
            has_nonzero=true
            break
        fi
    done <<< "$plan"
    [ "$has_nonzero" = "true" ]
}

@test "commit plan produces 7*width lines" {
    text_to_bitmap "A"
    local bitmap_file
    bitmap_file=$(mktemp -p "${BATS_TMPDIR}")
    printf '%s\n' "${BITMAP_ROWS[@]}" > "$bitmap_file"

    local plan
    plan=$(generate_commit_plan "$bitmap_file" "2025-01-05" 4 "none" "false")
    rm -f "$bitmap_file"

    local count
    count=$(echo "$plan" | wc -l)
    [ "$count" -eq 35 ]
}

@test "commit plan with compensation subtracts existing" {
    text_to_bitmap "I"
    local bitmap_file
    bitmap_file=$(mktemp -p "${BATS_TMPDIR}")
    printf '%s\n' "${BITMAP_ROWS[@]}" > "$bitmap_file"

    # I col 2 is all ON. Col 2, row 0 = bitmap_pos_to_date(start, 0, 2) = start + 14 days
    # 2025-01-05 + 14 = 2025-01-19 (Sunday of week 3)
    # Target=10, existing=3 -> needed=7
    local mock_contributions='[
        {"date": "2025-01-19", "contributionCount": 3}
    ]'

    local plan
    plan=$(generate_commit_plan "$bitmap_file" "2025-01-05" 10 "$mock_contributions" "false")
    rm -f "$bitmap_file"

    local found
    found=$(echo "$plan" | grep "2025-01-19" | head -1)
    local count="${found##* }"
    [ "$count" -eq 7 ]
}

@test "commit plan detects conflicts on gray pixels with existing contributions" {
    text_to_bitmap "I"
    local bitmap_file
    bitmap_file=$(mktemp -p "${BATS_TMPDIR}")
    printf '%s\n' "${BITMAP_ROWS[@]}" > "$bitmap_file"

    # I row 0 = 01110: pixel at col 0 is OFF (gray)
    # Date for row 0, col 0 = 2025-01-05 (Sunday)
    local mock_contributions='[
        {"date": "2025-01-05", "contributionCount": 5}
    ]'

    local plan
    plan=$(generate_commit_plan "$bitmap_file" "2025-01-05" 10 "$mock_contributions" "false")
    rm -f "$bitmap_file"

    local first_line
    first_line=$(echo "$plan" | head -1)
    local first_count="${first_line##* }"
    [ "$first_count" = "CONFLICT" ]
}

@test "commit plan inverse mode swaps pixel meaning" {
    text_to_bitmap " "
    local bitmap_file
    bitmap_file=$(mktemp -p "${BATS_TMPDIR}")
    printf '%s\n' "${BITMAP_ROWS[@]}" > "$bitmap_file"

    # Normal: space (all 0s) -> all gray -> count 0
    local plan_normal
    plan_normal=$(generate_commit_plan "$bitmap_file" "2025-01-05" 4 "none" "false")

    # Inverse: space (all 0s) -> pixel OFF = green -> count > 0
    local plan_inverse
    plan_inverse=$(generate_commit_plan "$bitmap_file" "2025-01-05" 4 "none" "true")
    rm -f "$bitmap_file"

    local normal_nonzero=false
    while IFS= read -r line; do
        local count="${line##* }"
        if [[ "$count" -gt 0 ]]; then
            normal_nonzero=true
            break
        fi
    done <<< "$plan_normal"

    local inverse_nonzero=false
    while IFS= read -r line; do
        local count="${line##* }"
        if [[ "$count" -gt 0 ]]; then
            inverse_nonzero=true
            break
        fi
    done <<< "$plan_inverse"

    [ "$normal_nonzero" = "false" ]
    [ "$inverse_nonzero" = "true" ]
}

@test "commit plan dates are valid YYYY-MM-DD format" {
    text_to_bitmap "A"
    local bitmap_file
    bitmap_file=$(mktemp -p "${BATS_TMPDIR}")
    printf '%s\n' "${BITMAP_ROWS[@]}" > "$bitmap_file"

    local plan
    plan=$(generate_commit_plan "$bitmap_file" "2025-01-05" 4 "none" "false")
    rm -f "$bitmap_file"

    while IFS= read -r line; do
        local pdate="${line%% *}"
        date -d "$pdate" +%Y-%m-%d > /dev/null 2>&1
    done <<< "$plan"
}

@test "commit plan target count controls commit count" {
    text_to_bitmap "I"
    local bitmap_file
    bitmap_file=$(mktemp -p "${BATS_TMPDIR}")
    printf '%s\n' "${BITMAP_ROWS[@]}" > "$bitmap_file"

    local plan_low plan_high
    plan_low=$(generate_commit_plan "$bitmap_file" "2025-01-05" 1 "none" "false")
    plan_high=$(generate_commit_plan "$bitmap_file" "2025-01-05" 10 "none" "false")
    rm -f "$bitmap_file"

    local sum_low=0 sum_high=0
    while IFS= read -r line; do
        local count="${line##* }"
        [[ "$count" == "CONFLICT" ]] && continue
        sum_low=$((sum_low + count))
    done <<< "$plan_low"
    while IFS= read -r line; do
        local count="${line##* }"
        [[ "$count" == "CONFLICT" ]] && continue
        sum_high=$((sum_high + count))
    done <<< "$plan_high"

    [ "$sum_high" -gt "$sum_low" ]
}

@test "commit plan with 0 existing uses full target" {
    text_to_bitmap "I"
    local bitmap_file
    bitmap_file=$(mktemp -p "${BATS_TMPDIR}")
    printf '%s\n' "${BITMAP_ROWS[@]}" > "$bitmap_file"

    local mock_contributions='[
        {"date": "2025-01-06", "contributionCount": 0}
    ]'

    local plan
    plan=$(generate_commit_plan "$bitmap_file" "2025-01-05" 5 "$mock_contributions" "false")
    rm -f "$bitmap_file"

    # I col 2 is all ON. Col 2, row 0 = 2025-01-19 (start + 14 days)
    local found
    found=$(echo "$plan" | grep "2025-01-19" | head -1)
    local count="${found##* }"
    [ "$count" -eq 5 ]
}
