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
