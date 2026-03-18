#!/usr/bin/env bats
# Tests for font.sh: bitmap font rendering.

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../scripts" && pwd)"

setup() {
    source "${SCRIPT_DIR}/font.sh"
}

@test "render_char A produces 7 rows" {
    local output
    output=$(render_char "A")
    local count
    count=$(echo "$output" | wc -l)
    [ "$count" -eq 7 ]
}

@test "render_char A first row is 01110" {
    local output
    output=$(render_char "A")
    local first_row
    first_row=$(echo "$output" | head -1)
    [ "$first_row" = "01110" ]
}

@test "render_char A each row is 5 chars wide" {
    local output
    output=$(render_char "A")
    while IFS= read -r row; do
        [ "${#row}" -eq 5 ]
    done <<< "$output"
}

@test "render_char space produces all zeros" {
    local output
    output=$(render_char " ")
    while IFS= read -r row; do
        [ "$row" = "00000" ]
    done <<< "$output"
}

@test "render_char unknown char renders as blank" {
    local output
    output=$(render_char "~")
    while IFS= read -r row; do
        [ "$row" = "00000" ]
    done <<< "$output"
}

@test "all letters A-Z are defined and 7 rows each" {
    for letter in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z; do
        local output
        output=$(render_char "$letter")
        local count
        count=$(echo "$output" | wc -l)
        [ "$count" -eq 7 ]
    done
}

@test "all digits 0-9 are defined and 7 rows each" {
    for digit in 0 1 2 3 4 5 6 7 8 9; do
        local output
        output=$(render_char "$digit")
        local count
        count=$(echo "$output" | wc -l)
        [ "$count" -eq 7 ]
    done
}

@test "render_text HI produces 7 rows" {
    local output
    output=$(render_text "HI")
    local count
    count=$(echo "$output" | wc -l)
    [ "$count" -eq 7 ]
}

@test "render_text HI width is 11 (5+1+5)" {
    local output
    output=$(render_text "HI")
    local first_row
    first_row=$(echo "$output" | head -1)
    [ "${#first_row}" -eq 11 ]
}

@test "render_text ABC width is 17 (5+1+5+1+5)" {
    local output
    output=$(render_text "ABC")
    local first_row
    first_row=$(echo "$output" | head -1)
    [ "${#first_row}" -eq 17 ]
}

@test "render_text converts lowercase to uppercase" {
    local output_lower output_upper
    output_lower=$(render_text "hi")
    output_upper=$(render_text "HI")
    [ "$output_lower" = "$output_upper" ]
}

@test "render_text empty string produces no output" {
    local output
    output=$(render_text "")
    [ -z "$output" ]
}

@test "render_text single char width is 5" {
    local output
    output=$(render_text "X")
    local first_row
    first_row=$(echo "$output" | head -1)
    [ "${#first_row}" -eq 5 ]
}
