#!/usr/bin/env bash
# Query existing GitHub contributions and compute compensation.

set -euo pipefail

# query_contributions: Fetch contribution calendar via GraphQL.
# Args: $1 = GitHub token, $2 = username, $3 = from_date (YYYY-MM-DD), $4 = to_date (YYYY-MM-DD)
# Output: JSON array of {date, contributionCount} objects
query_contributions() {
    local token="${1}" username="${2}" from_date="${3}" to_date="${4}"

    local query
    query=$(cat <<GRAPHQL
{
  user(login: "$username") {
    contributionsCollection(from: "${from_date}T00:00:00Z", to: "${to_date}T23:59:59Z") {
      contributionCalendar {
        weeks {
          contributionDays {
            date
            contributionCount
          }
        }
      }
    }
  }
}
GRAPHQL
    )

    local response
    response=$(gh api graphql -f query="$query" 2>/dev/null) || {
        echo "ERROR: GraphQL query failed" >&2
        return 1
    }

    echo "$response" | jq -r '
        [.data.user.contributionsCollection.contributionCalendar.weeks[]
         .contributionDays[] | {date, contributionCount}]'
}

# get_contribution_count: Get existing contribution count for a specific date.
# Args: $1 = contributions_json (from query_contributions), $2 = date (YYYY-MM-DD)
# Output: integer count
get_contribution_count() {
    local contributions_json="${1}" target_date="${2}"
    echo "$contributions_json" | jq -r \
        --arg d "$target_date" \
        '[.[] | select(.date == $d) | .contributionCount] | first // 0'
}

# get_max_contribution_count: Get the highest contribution count from the data.
# Args: $1 = contributions_json
# Output: integer (max count, 0 if empty)
get_max_contribution_count() {
    echo "${1}" | jq '[.[].contributionCount] | max // 0'
}

# merge_contribution_jsons: Concatenate any number of contribution JSON arrays.
# Reason: a paint can span multiple calendar years; GraphQL caps each query at 1 year,
# so we query per year then merge for downstream lookup and max computation.
# Args: any number of JSON array strings
# Output: single JSON array
merge_contribution_jsons() {
    if [[ $# -eq 0 ]]; then
        echo "[]"
        return
    fi
    printf '%s\n' "$@" | jq -s 'add // []'
}

# years_in_range: List the calendar years (one per line) spanned by [start_date, end_date].
# Args: $1 = start_date (YYYY-MM-DD), $2 = end_date (YYYY-MM-DD)
# Output: years one per line, ascending
years_in_range() {
    local start_year end_year y
    start_year=$(date -d "${1}" +%Y) || return 1
    end_year=$(date -d "${2}" +%Y) || return 1
    for ((y = start_year; y <= end_year; y++)); do
        echo "$y"
    done
}
