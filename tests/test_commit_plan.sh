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

    # I has pixels on, so some counts should be > 0
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
    # A is 5 columns wide, 7 rows = 35 entries
    [ "$count" -eq 35 ]
}

@test "commit plan with compensation detects conflicts" {
    text_to_bitmap "I"
    local bitmap_file
    bitmap_file=$(mktemp -p "${BATS_TMPDIR}")
    printf '%s\n' "${BITMAP_ROWS[@]}" > "$bitmap_file"

    # Mock contributions: day that needs to be gray (pixel=0) has existing contributions
    # I has pixels off at row 0, col 0 (top-left is 0 for "I": 01110)
    # Row 0 = Sunday 2025-01-05
    local mock_contributions='[
        {"date": "2025-01-05", "contributionCount": 5},
        {"date": "2025-01-06", "contributionCount": 0},
        {"date": "2025-01-07", "contributionCount": 0}
    ]'

    local plan
    plan=$(generate_commit_plan "$bitmap_file" "2025-01-05" 4 "$mock_contributions" "false")
    rm -f "$bitmap_file"

    # The first pixel of I is 0 (gray), but date 2025-01-05 has 5 contributions
    # Should be CONFLICT
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

    # Normal: space (all 0s) -> all level 0 -> count 0
    local plan_normal
    plan_normal=$(generate_commit_plan "$bitmap_file" "2025-01-05" 4 "none" "false")

    # Inverse: space (all 0s) -> pixel OFF -> high intensity -> count > 0
    local plan_inverse
    plan_inverse=$(generate_commit_plan "$bitmap_file" "2025-01-05" 4 "none" "true")
    rm -f "$bitmap_file"

    # Normal should have all zeros
    local normal_nonzero=false
    while IFS= read -r line; do
        local count="${line##* }"
        if [[ "$count" -gt 0 ]]; then
            normal_nonzero=true
            break
        fi
    done <<< "$plan_normal"

    # Inverse should have non-zeros
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
        # Validate date format with date command
        date -d "$pdate" +%Y-%m-%d > /dev/null 2>&1
    done <<< "$plan"
}

@test "commit plan intensity level controls commit count" {
    text_to_bitmap "I"
    local bitmap_file
    bitmap_file=$(mktemp -p "${BATS_TMPDIR}")
    printf '%s\n' "${BITMAP_ROWS[@]}" > "$bitmap_file"

    local plan_low plan_high
    plan_low=$(generate_commit_plan "$bitmap_file" "2025-01-05" 1 "none" "false")
    plan_high=$(generate_commit_plan "$bitmap_file" "2025-01-05" 4 "none" "false")
    rm -f "$bitmap_file"

    # Sum all commits for each plan
    local sum_low=0 sum_high=0
    while IFS= read -r line; do
        local count="${line##* }"
        [[ "$count" == "CONFLICT" ]] && continue
        ((sum_low += count)) || true
    done <<< "$plan_low"
    while IFS= read -r line; do
        local count="${line##* }"
        [[ "$count" == "CONFLICT" ]] && continue
        ((sum_high += count)) || true
    done <<< "$plan_high"

    # Higher intensity should produce more total commits
    [ "$sum_high" -gt "$sum_low" ]
}
